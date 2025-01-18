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
		
		Make sure each effect description is written in plain English that any adult can understand. Do not include any other text or commentary in your response.`;

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
	const responseText = data.candidates[0].content.parts[0].text;
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
