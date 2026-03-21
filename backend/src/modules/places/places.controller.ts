import type { Request, Response } from 'express'
import { config } from '../../config'
import { logger } from '../../shared/utils/logger'

/**
 * Uses Google Places API (New) — POST-based endpoint.
 * Docs: https://developers.google.com/maps/documentation/places/web-service/place-autocomplete
 */
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

    const language = (req.query.language as string) || 'en'
    // Build request body for Places API (New)
    const body: Record<string, unknown> = {
      input,
      languageCode: language,
      includedRegionCodes: ['IL'],
      includedPrimaryTypes: ['(cities)'],
    }

    try {
      const response = await fetch('https://places.googleapis.com/v1/places:autocomplete', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': config.google_places.apiKey,
        },
        body: JSON.stringify(body),
      })

      const json = await response.json() as {
        suggestions?: Array<{
          placePrediction?: {
            placeId: string
            text?: { text: string }
            structuredFormat?: {
              mainText?: { text: string }
              secondaryText?: { text: string }
            }
          }
        }>
        error?: { message: string; status: string }
      }

      if (json.error) {
        logger.warn('Google Places API (New) error', { error: json.error.message, status: json.error.status })
        res.json({ data: [] })
        return
      }

      const suggestions = (json.suggestions || [])
        .filter((s) => s.placePrediction)
        .map((s) => {
          const p = s.placePrediction!
          return {
            description: p.text?.text || '',
            placeId: p.placeId,
            mainText: p.structuredFormat?.mainText?.text || p.text?.text || '',
            secondaryText: p.structuredFormat?.secondaryText?.text || '',
          }
        })

      res.json({ data: suggestions })
    } catch (err) {
      logger.error('Places autocomplete fetch failed', {
        error: err instanceof Error ? err.message : String(err),
      })
      res.json({ data: [] })
    }
  },
}
