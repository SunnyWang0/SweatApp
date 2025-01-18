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

interface GeminiResponse {
	candidates: Array<{
		content: {
			parts: Array<{
				text: string;
			}>;
		};
	}>;
}

interface RequestBody {
	image: string;
}

const GEMINI_API_URL = 'https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash-thinking-exp-1219:generateContent';

async function analyzePreworkoutImage(imageBase64: string, apiKey: string): Promise<PreworkoutAnalysis> {
	const prompt = `Analyze this preworkout supplement label. For each ingredient:
		1. List its exact quantity as shown on the label
		2. Explain what this ingredient does in clear, straightforward language
		3. Describe its main benefits and effects in full sentences that any adult can understand
		
		Then rate the following qualities on a scale of 1-100 based on the ingredients and their effects. Also make sure to consider the quantity of the ingredient as it can effect how much you feel each quality:
		- Pump (muscle blood flow and vasodilation)
		- Energy (stimulant effects and alertness)
		- Focus (mental clarity and concentration)
		- Recovery (muscle recovery and reduced soreness)
		- Endurance (stamina and performance)
		
		Format the response as JSON with this structure:
		{
			"ingredients": [
				{
					"name": string,
					"quantity": string,
					"effects": string[]  // Each effect should be a complete, clear sentence or sentences explaining what the ingredient does
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
		
		Make sure each effect description is written in plain English that any adult can understand, while still being accurate and informative. Do not use overly technical language, but also don't oversimplify to the point of losing important information.
		
		Do not include any other text or commentary in your response.`;

	const requestBody = {
		contents: [{
			parts: [
				{ text: prompt },
				{
					inline_data: {
						mime_type: 'image/jpeg',
						data: imageBase64
					}
				}
			]
		}],
		generation_config: {
			temperature: 0.9,
			topP: 1,
			topK: 32,
			maxOutputTokens: 8192,
		}
	};

	const response = await fetch(GEMINI_API_URL, {
		method: 'POST',
		headers: {
			'Content-Type': 'application/json',
			'Authorization': `Bearer ${apiKey}`
		},
		body: JSON.stringify(requestBody)
	});

	if (!response.ok) {
		throw new Error(`Gemini API error: ${response.statusText}`);
	}

	const data = await response.json() as GeminiResponse;
	return JSON.parse(data.candidates[0].content.parts[0].text) as PreworkoutAnalysis;
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
			
			return new Response(JSON.stringify(analysis), {
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
