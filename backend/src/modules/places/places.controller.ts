import type { Request, Response } from 'express'
import { config } from '../../config'
import { logger } from '../../shared/utils/logger'

export const placesController = {
  async autocomplete(req: Request, res: Response) {
    const input = (req.query.input as string || '').trim()
    if (!input || input.length < 2) {
      res.json({ data: [] })
      return
    }

    if (!config.google_places.isConfigured) {
      logger.warn('Places autocomplete called but GOOGLE_PLACES_API_KEY is not set')
      res.json({ data: [] })
      return
    }

    const types = (req.query.types as string) || '(cities)'
    const components = (req.query.components as string) || 'country:il'
    const language = (req.query.language as string) || 'en'

    const url = new URL('https://maps.googleapis.com/maps/api/place/autocomplete/json')
    url.searchParams.set('input', input)
    url.searchParams.set('types', types)
    url.searchParams.set('components', components)
    url.searchParams.set('language', language)
    url.searchParams.set('key', config.google_places.apiKey)

    try {
      const response = await fetch(url.toString())
      const json = await response.json() as {
        status: string
        predictions?: Array<{
          description: string
          place_id: string
          structured_formatting?: {
            main_text: string
            secondary_text?: string
          }
          types?: string[]
        }>
        error_message?: string
      }

      if (json.status !== 'OK' && json.status !== 'ZERO_RESULTS') {
        logger.warn('Google Places API error', { status: json.status, error: json.error_message })
        res.json({ data: [] })
        return
      }

      const suggestions = (json.predictions || []).map((p) => ({
        description: p.description,
        placeId: p.place_id,
        mainText: p.structured_formatting?.main_text || p.description,
        secondaryText: p.structured_formatting?.secondary_text || '',
      }))

      res.json({ data: suggestions })
    } catch (err) {
      logger.error('Places autocomplete fetch failed', {
        error: err instanceof Error ? err.message : String(err),
      })
      res.json({ data: [] })
    }
  },
}
