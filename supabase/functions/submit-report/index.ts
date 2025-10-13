import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

interface ReportSubmission {
  image: File
  reporter_id?: string
  phone?: string
  lat: number
  lng: number
  description: string
  timestamp: string
}

interface ReportData {
  reporter_uid?: string
  reporter_name?: string
  message: string
  location: {
    lat: number
    lng: number
    address?: string
  }
  image_path: string
  type?: string
  confidence?: number
  status: string
  lifecycle_status: string
  created_at: string
  ai_labels?: any
  ai_timestamp?: string
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Parse multipart form data
    const formData = await req.formData()
    const reportData = await parseReportSubmission(formData)

    // Validate required fields
    validateReportSubmission(reportData)

    // Upload image to storage
    const imagePath = await uploadImageToStorage(supabaseClient, reportData.image)

    // Get or create reporter
    const reporterInfo = await getOrCreateReporter(supabaseClient, reportData)

    // Prepare report data for database
    const reportRecord: ReportData = {
      reporter_uid: reporterInfo.uid,
      reporter_name: reporterInfo.name,
      message: reportData.description,
      location: {
        lat: reportData.lat,
        lng: reportData.lng
      },
      image_path: imagePath,
      status: 'pending',
      lifecycle_status: 'pending',
      created_at: reportData.timestamp || new Date().toISOString()
    }

    // Insert report into database
    const { data: insertedReport, error: insertError } = await supabaseClient
      .from('reports')
      .insert(reportRecord)
      .select()
      .single()

    if (insertError) {
      throw new Error(`Failed to insert report: ${insertError.message}`)
    }

    // Trigger classification (async)
    await triggerImageClassification(supabaseClient, insertedReport.id)

    // Emit real-time event for new report
    await emitReportCreatedEvent(supabaseClient, insertedReport)

    // Log successful submission
    await logAuditEvent(supabaseClient, {
      entity_type: 'report',
      entity_id: insertedReport.id,
      action: 'created',
      user_id: reporterInfo.uid,
      details: {
        location: reportData.lat + ',' + reportData.lng,
        has_image: true,
        description_length: reportData.description.length
      }
    })

    return new Response(
      JSON.stringify({
        success: true,
        report_id: insertedReport.id,
        message: 'Report submitted successfully',
        image_path: imagePath
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 201
      }
    )

  } catch (error) {
    console.error('Error in submit-report function:', error)
    
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || 'Internal server error'
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500
      }
    )
  }
})

/**
 * Parse multipart form data into structured report submission
 */
async function parseReportSubmission(formData: FormData): Promise<ReportSubmission> {
  const image = formData.get('image') as File
  const reporter_id = formData.get('reporter_id') as string
  const phone = formData.get('phone') as string
  const lat = parseFloat(formData.get('lat') as string)
  const lng = parseFloat(formData.get('lng') as string)
  const description = formData.get('description') as string
  const timestamp = formData.get('timestamp') as string

  if (!image) {
    throw new Error('Image file is required')
  }

  if (!description || description.trim().length === 0) {
    throw new Error('Description is required')
  }

  if (isNaN(lat) || isNaN(lng)) {
    throw new Error('Valid latitude and longitude are required')
  }

  if (!reporter_id && !phone) {
    throw new Error('Either reporter_id or phone is required')
  }

  return {
    image,
    reporter_id: reporter_id || undefined,
    phone: phone || undefined,
    lat,
    lng,
    description: description.trim(),
    timestamp: timestamp || new Date().toISOString()
  }
}

/**
 * Validate report submission data
 */
function validateReportSubmission(data: ReportSubmission): void {
  // Validate image file
  if (!data.image || data.image.size === 0) {
    throw new Error('Image file is required and cannot be empty')
  }

  // Check image size (max 10MB)
  const maxSize = 10 * 1024 * 1024 // 10MB
  if (data.image.size > maxSize) {
    throw new Error('Image file size must be less than 10MB')
  }

  // Check image type
  const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
  if (!allowedTypes.includes(data.image.type)) {
    throw new Error('Image must be JPEG, PNG, or WebP format')
  }

  // Validate coordinates
  if (data.lat < -90 || data.lat > 90) {
    throw new Error('Latitude must be between -90 and 90')
  }

  if (data.lng < -180 || data.lng > 180) {
    throw new Error('Longitude must be between -180 and 180')
  }

  // Validate description length
  if (data.description.length < 10) {
    throw new Error('Description must be at least 10 characters long')
  }

  if (data.description.length > 1000) {
    throw new Error('Description must be less than 1000 characters')
  }
}

/**
 * Upload image to Supabase Storage
 */
async function uploadImageToStorage(
  supabaseClient: any,
  image: File
): Promise<string> {
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-')
  const fileName = `reports/${timestamp}-${crypto.randomUUID()}.${getFileExtension(image.name)}`
  
  const { data, error } = await supabaseClient.storage
    .from('report-images')
    .upload(fileName, image, {
      contentType: image.type,
      upsert: false
    })

  if (error) {
    throw new Error(`Failed to upload image: ${error.message}`)
  }

  return fileName
}

/**
 * Get file extension from filename
 */
function getFileExtension(filename: string): string {
  return filename.split('.').pop()?.toLowerCase() || 'jpg'
}

/**
 * Get or create reporter record
 */
async function getOrCreateReporter(
  supabaseClient: any,
  data: ReportSubmission
): Promise<{ uid: string; name: string }> {
  // If reporter_id is provided, get existing reporter
  if (data.reporter_id) {
    const { data: reporter, error } = await supabaseClient
      .from('reporter')
      .select('id, name, user_id')
      .eq('id', data.reporter_id)
      .single()

    if (error && error.code !== 'PGRST116') {
      throw new Error(`Failed to get reporter: ${error.message}`)
    }

    if (reporter) {
      return {
        uid: reporter.user_id || data.reporter_id,
        name: reporter.name
      }
    }
  }

  // If phone is provided, try to find existing reporter by phone
  if (data.phone) {
    const { data: reporter, error } = await supabaseClient
      .from('reporter')
      .select('id, name, user_id')
      .eq('phone', data.phone)
      .single()

    if (error && error.code !== 'PGRST116') {
      throw new Error(`Failed to get reporter by phone: ${error.message}`)
    }

    if (reporter) {
      return {
        uid: reporter.user_id || reporter.id,
        name: reporter.name
      }
    }
  }

  // Create new reporter record
  const reporterName = data.phone ? `Reporter-${data.phone.slice(-4)}` : 'Anonymous'
  
  const { data: newReporter, error: createError } = await supabaseClient
    .from('reporter')
    .insert({
      name: reporterName,
      phone: data.phone || null,
      verified: false
    })
    .select()
    .single()

  if (createError) {
    throw new Error(`Failed to create reporter: ${createError.message}`)
  }

  return {
    uid: newReporter.id,
    name: newReporter.name
  }
}

/**
 * Trigger image classification
 */
async function triggerImageClassification(
  supabaseClient: any,
  reportId: string
): Promise<void> {
  try {
    // Call the classify-image function
    const { data, error } = await supabaseClient.functions.invoke('classify-image', {
      body: { report_id: reportId }
    })

    if (error) {
      console.warn('Failed to trigger classification:', error)
      // Don't throw error here as classification is not critical for submission
    }
  } catch (error) {
    console.warn('Error triggering classification:', error)
    // Continue execution even if classification fails
  }
}

/**
 * Emit real-time event for new report
 */
async function emitReportCreatedEvent(
  supabaseClient: any,
  report: any
): Promise<void> {
  try {
    // Emit to public reports channel
    await supabaseClient.realtime
      .channel('public:reports')
      .send({
        type: 'broadcast',
        event: 'report.created',
        payload: {
          id: report.id,
          status: report.status,
          lifecycle_status: report.lifecycle_status,
          type: report.type,
          lat: report.location?.lat,
          lng: report.location?.lng,
          message: report.message,
          reporter_name: report.reporter_name,
          created_at: report.created_at,
          confidence: report.ai_confidence,
          has_image: !!report.image_path
        }
      })

    // Emit to admin channel
    await supabaseClient.realtime
      .channel('private:admin')
      .send({
        type: 'broadcast',
        event: 'report.created',
        payload: {
          id: report.id,
          status: report.status,
          lifecycle_status: report.lifecycle_status,
          type: report.type,
          lat: report.location?.lat,
          lng: report.location?.lng,
          message: report.message,
          reporter_name: report.reporter_name,
          reporter_uid: report.reporter_uid,
          created_at: report.created_at,
          confidence: report.ai_confidence,
          has_image: !!report.image_path
        }
      })

  } catch (error) {
    console.warn('Failed to emit report created event:', error)
    // Don't throw error as real-time events are not critical
  }
}

/**
 * Log audit event
 */
async function logAuditEvent(
  supabaseClient: any,
  event: {
    entity_type: string
    entity_id: string
    action: string
    user_id?: string
    details?: any
  }
): Promise<void> {
  try {
    await supabaseClient
      .from('audit_log')
      .insert({
        entity_type: event.entity_type,
        entity_id: event.entity_id,
        action: event.action,
        user_id: event.user_id,
        details: event.details,
        created_at: new Date().toISOString()
      })
  } catch (error) {
    console.warn('Failed to log audit event:', error)
    // Don't throw error as audit logging is not critical
  }
}
