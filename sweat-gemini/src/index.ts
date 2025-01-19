interface PreworkoutAnalysis {
	ingredients: Array<{
		name: string;
		quantity: string;
		effects: string[];
	}>;
	qualities: {
		pump: number;
		energy: number;
		focus: number;
		recovery: number;
		endurance: number;
	};
}

interface Env {
	GEMINI_API_KEY: string;
}

interface RequestBody {
	image: string;
}

interface GeminiResponse {
	candidates: Array<{
		content: {
			parts: Array<{
				text: string;
			}>;
		};
	}>;
}

const MODEL_NAME = 'gemini-2.0-flash-thinking-exp-1219';

async function analyzePreworkoutImage(imageBase64: string, apiKey: string): Promise<PreworkoutAnalysis> {
	const prompt = `Analyze this preworkout supplement label with scientific precision. For each ingredient:
		1. List its exact quantity as shown on the label, including unit of measurement
		2. Compare the quantity to clinically effective dosages from scientific literature
		3. Explain its primary mechanisms of action and physiological effects
		4. List specific benefits with consideration of the provided dosage
		
		Then rate the following qualities on a scale of 1-100, where:
		- 1-20: Minimal/negligible effect
		- 21-40: Light effect
		- 41-60: Moderate effect
		- 61-80: Strong effect
		- 81-100: Very strong effect

		Consider these specific criteria for each rating:

		Pump (muscle blood flow and vasodilation):
		- Presence and dosage of nitric oxide boosters (L-Citrulline, Arginine, etc.)
		- Vasodilators and blood flow enhancers
		- Ingredients that improve nutrient delivery
		- Synergistic effects between ingredients

		Energy (stimulant effects and alertness):
		- Caffeine content and form (anhydrous, di-caffeine malate, etc.)
		- Additional stimulants present
		- Energy sustaining ingredients
		- Potential crash factors

		Focus (mental clarity and concentration):
		- Nootropic ingredients and dosages
		- Cognitive enhancers
		- Focus-supporting amino acids
		- Stimulant contribution to focus

		Recovery (muscle recovery and reduced soreness):
		- Branch chain amino acids (BCAAs)
		- Essential amino acids (EAAs)
		- Anti-inflammatory ingredients
		- Cellular hydration enhancers

		Endurance (stamina and performance):
		- Beta-alanine content
		- Performance enhancers
		- Fatigue-fighting ingredients
		- ATP production supporters

		Format the response as JSON with this structure:
		{
			"ingredients": [
				{
					"name": string,
					"quantity": string,
					"effects": string[]
				}
			],
			"qualities": {
				"pump": number,
				"energy": number,
				"focus": number,
				"recovery": number,
				"endurance": number
			}
		}
		
		Ensure each effect description is evidence-based and clearly explains the mechanism of action. Consider ingredient interactions and timing effects. Effects should be written in conversational English that any adult can understand. 
		
		Do not include any other text or commentary in your response.`;

	const requestBody = {
		contents: [{
			parts: [
				{ text: prompt },
				{
					inlineData: {
						mimeType: 'image/jpeg',
						data: imageBase64
					}
				}
			]
		}],
		generationConfig: {
			temperature: 1,
			topP: 0.95,
			topK: 64,
			maxOutputTokens: 8192,
		}
	};

	const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${MODEL_NAME}:generateContent?key=${apiKey}`, {
		method: 'POST',
		headers: {
			'Content-Type': 'application/json'
		},
		body: JSON.stringify(requestBody)
	});

	if (!response.ok) {
		throw new Error(`Gemini API error: ${response.statusText}`);
	}

	const data = await response.json() as GeminiResponse;
	
	if (!data.candidates?.[0]?.content?.parts?.[0]?.text) {
		throw new Error('Invalid response format from Gemini API');
	}

	// Extract the JSON string from the response text
	const responseText = data.candidates[0].content.parts[1].text;
	const jsonMatch = responseText.match(/\{[\s\S]*\}/);
	
	if (!jsonMatch) {
		throw new Error('Could not find JSON in response');
	}

	try {
		return JSON.parse(jsonMatch[0]) as PreworkoutAnalysis;
	} catch (e) {
		throw new Error('Failed to parse response JSON');
	}
}

export default {
	async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
		if (request.method !== 'POST') {
			return new Response('Method not allowed', { status: 405 });
		}

		try {
			const body = await request.json() as RequestBody;
			
			if (!body.image) {
				return new Response('Image data is required', { status: 400 });
			}

			const analysis = await analyzePreworkoutImage(body.image, env.GEMINI_API_KEY);
			
			return new Response(JSON.stringify(analysis, null, 2), {
				headers: { 'Content-Type': 'application/json' }
			});
		} catch (error) {
			const errorMessage = error instanceof Error ? error.message : 'An unknown error occurred';
			return new Response(JSON.stringify({ error: errorMessage }), {
				status: 500,
				headers: { 'Content-Type': 'application/json' }
			});
		}
	},
} satisfies ExportedHandler<Env>;
