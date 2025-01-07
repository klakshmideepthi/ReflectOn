Structured Outputs
==================

Ensure responses adhere to a JSON schema.

Try it out
----------

Try it out in the [Playground](/playground) or generate a ready-to-use schema definition to experiment with structured outputs.

Generate

Introduction
------------

JSON is one of the most widely used formats in the world for applications to exchange data.

Structured Outputs is a feature that ensures the model will always generate responses that adhere to your supplied [JSON Schema](https://json-schema.org/overview/what-is-jsonschema), so you don't need to worry about the model omitting a required key, or hallucinating an invalid enum value.

Some benefits of Structured Outputs include:

1.  **Reliable type-safety:** No need to validate or retry incorrectly formatted responses
2.  **Explicit refusals:** Safety-based model refusals are now programmatically detectable
3.  **Simpler prompting:** No need for strongly worded prompts to achieve consistent formatting

In addition to supporting JSON Schema in the REST API, the OpenAI SDKs for [Python](https://github.com/openai/openai-python/blob/main/helpers.md#structured-outputs-parsing-helpers) and [JavaScript](https://github.com/openai/openai-node/blob/master/helpers.md#structured-outputs-parsing-helpers) also make it easy to define object schemas using [Pydantic](https://docs.pydantic.dev/latest/) and [Zod](https://zod.dev/) respectively. Below, you can see how to extract information from unstructured text that conforms to a schema defined in code.

Getting a structured response

```javascript
import OpenAI from "openai";
import { zodResponseFormat } from "openai/helpers/zod";
import { z } from "zod";

const openai = new OpenAI();

const CalendarEvent = z.object({
  name: z.string(),
  date: z.string(),
  participants: z.array(z.string()),
});

const completion = await openai.beta.chat.completions.parse({
  model: "gpt-4o-2024-08-06",
  messages: [
    { role: "system", content: "Extract the event information." },
    { role: "user", content: "Alice and Bob are going to a science fair on Friday." },
  ],
  response_format: zodResponseFormat(CalendarEvent, "event"),
});

const event = completion.choices[0].message.parsed;
```

```python
from pydantic import BaseModel
from openai import OpenAI

client = OpenAI()

class CalendarEvent(BaseModel):
    name: str
    date: str
    participants: list[str]

completion = client.beta.chat.completions.parse(
    model="gpt-4o-2024-08-06",
    messages=[
        {"role": "system", "content": "Extract the event information."},
        {"role": "user", "content": "Alice and Bob are going to a science fair on Friday."},
    ],
    response_format=CalendarEvent,
)

event = completion.choices[0].message.parsed
```

### Supported models

Structured Outputs are available in our [latest large language models](/docs/models), starting with GPT-4o:

*   `o1-2024-12-17` and later
*   `gpt-4o-mini-2024-07-18` and later
*   `gpt-4o-2024-08-06` and later

Older models like `gpt-4-turbo` and earlier may use [JSON mode](#json-mode) instead.

When to use Structured Outputs via function calling vs via response\_format

-------------------------------------------------------------------------------

Structured Outputs is available in two forms in the OpenAI API:

1.  When using [function calling](/docs/guides/function-calling)
2.  When using a `json_schema` response format

Function calling is useful when you are building an application that bridges the models and functionality of your application.

For example, you can give the model access to functions that query a database in order to build an AI assistant that can help users with their orders, or functions that can interact with the UI.

Conversely, Structured Outputs via `response_format` are more suitable when you want to indicate a structured schema for use when the model responds to the user, rather than when the model calls a tool.

For example, if you are building a math tutoring application, you might want the assistant to respond to your user using a specific JSON Schema so that you can generate a UI that displays different parts of the model's output in distinct ways.

Put simply:

*   If you are connecting the model to tools, functions, data, etc. in your system, then you should use function calling
*   If you want to structure the model's output when it responds to the user, then you should use a structured `response_format`

The remainder of this guide will focus on non-function calling use cases in the Chat Completions API. To learn more about how to use Structured Outputs with function calling, check out the [Function Calling](/docs/guides/function-calling#function-calling-with-structured-outputs) guide.

### Structured Outputs vs JSON mode

Structured Outputs is the evolution of [JSON mode](#json-mode). While both ensure valid JSON is produced, only Structured Outputs ensure schema adherance. Both Structured Outputs and JSON mode are supported in the Chat Completions API, Assistants API, Fine-tuning API and Batch API.

We recommend always using Structured Outputs instead of JSON mode when possible.

However, Structured Outputs with `response_format: {type: "json_schema", ...}` is only supported with the `gpt-4o-mini`, `gpt-4o-mini-2024-07-18`, and `gpt-4o-2024-08-06` model snapshots and later.

||Structured Outputs|JSON Mode|
|---|---|---|
|Outputs valid JSON|Yes|Yes|
|Adheres to schema|Yes (see supported schemas)|No|
|Compatible models|gpt-4o-mini, gpt-4o-2024-08-06, and later|gpt-3.5-turbo, gpt-4-* and gpt-4o-* models|
|Enabling|response_format: { type: "json_schema", json_schema: {"strict": true, "schema": ...} }|response_format: { type: "json_object" }|

Examples
--------

Chain of thoughtStructured data extractionUI generationModeration

### Chain of thought

You can ask the model to output an answer in a structured, step-by-step way, to guide the user through the solution.

Structured Outputs for chain-of-thought math tutoring

```javascript
import OpenAI from "openai";
import { z } from "zod";
import { zodResponseFormat } from "openai/helpers/zod";

const openai = new OpenAI();

const Step = z.object({
  explanation: z.string(),
  output: z.string(),
});

const MathReasoning = z.object({
  steps: z.array(Step),
  final_answer: z.string(),
});

const completion = await openai.beta.chat.completions.parse({
  model: "gpt-4o-2024-08-06",
  messages: [
    { role: "system", content: "You are a helpful math tutor. Guide the user through the solution step by step." },
    { role: "user", content: "how can I solve 8x + 7 = -23" },
  ],
  response_format: zodResponseFormat(MathReasoning, "math_reasoning"),
});

const math_reasoning = completion.choices[0].message.parsed;
```

```python
from pydantic import BaseModel
from openai import OpenAI

client = OpenAI()

class Step(BaseModel):
    explanation: str
    output: str

class MathReasoning(BaseModel):
    steps: list[Step]
    final_answer: str

completion = client.beta.chat.completions.parse(
    model="gpt-4o-2024-08-06",
    messages=[
        {"role": "system", "content": "You are a helpful math tutor. Guide the user through the solution step by step."},
        {"role": "user", "content": "how can I solve 8x + 7 = -23"}
    ],
    response_format=MathReasoning,
)

math_reasoning = completion.choices[0].message.parsed
```

```bash
curl https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4o-2024-08-06",
    "messages": [
      {
        "role": "system",
        "content": "You are a helpful math tutor. Guide the user through the solution step by step."
      },
      {
        "role": "user",
        "content": "how can I solve 8x + 7 = -23"
      }
    ],
    "response_format": {
      "type": "json_schema",
      "json_schema": {
        "name": "math_reasoning",
        "schema": {
          "type": "object",
          "properties": {
            "steps": {
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "explanation": { "type": "string" },
                  "output": { "type": "string" }
                },
                "required": ["explanation", "output"],
                "additionalProperties": false
              }
            },
            "final_answer": { "type": "string" }
          },
          "required": ["steps", "final_answer"],
          "additionalProperties": false
        },
        "strict": true
      }
    }
  }'
```

#### Example response

```json
{
  "steps": [
    {
      "explanation": "Start with the equation 8x + 7 = -23.",
      "output": "8x + 7 = -23"
    },
    {
      "explanation": "Subtract 7 from both sides to isolate the term with the variable.",
      "output": "8x = -23 - 7"
    },
    {
      "explanation": "Simplify the right side of the equation.",
      "output": "8x = -30"
    },
    {
      "explanation": "Divide both sides by 8 to solve for x.",
      "output": "x = -30 / 8"
    },
    {
      "explanation": "Simplify the fraction.",
      "output": "x = -15 / 4"
    }
  ],
  "final_answer": "x = -15 / 4"
}
```

How to use Structured Outputs with response\_format

-------------------------------------------------------

You can use Structured Outputs with the new SDK helper to parse the model's output into your desired format, or you can specify the JSON schema directly.

**Note:** the first request you make with any schema will have additional latency as our API processes the schema, but subsequent requests with the same schema will not have additional latency.

SDK objectsManual schema

Step 1: Define your object

First you must define an object or data structure to represent the JSON Schema that the model should be constrained to follow. See the [examples](/docs/guides/structured-outputs#examples) at the top of this guide for reference.

While Structured Outputs supports much of JSON Schema, some features are unavailable either for performance or technical reasons. See [here](/docs/guides/structured-outputs#supported-schemas) for more details.

For example, you can define an object like this:

```python
from pydantic import BaseModel

class Step(BaseModel):
  explanation: str
  output: str

class MathResponse(BaseModel):
  steps: list[Step]
  final_answer: str
```

```javascript
import { z } from "zod";
import { zodResponseFormat } from "openai/helpers/zod";

const Step = z.object({
explanation: z.string(),
output: z.string(),
});

const MathResponse = z.object({
steps: z.array(Step),
final_answer: z.string(),
});
```

#### Tips for your data structure

To maximize the quality of model generations, we recommend the following:

*   Name keys clearly and intuitively
*   Create clear titles and descriptions for important keys in your structure
*   Create and use evals to determine the structure that works best for your use case

Step 2: Supply your object in the API call

You can use the `parse` method to automatically parse the JSON response into the object you defined.

Under the hood, the SDK takes care of supplying the JSON schema corresponding to your data structure, and then parsing the response as an object.

```python
completion = client.beta.chat.completions.parse(
  model="gpt-4o-2024-08-06",
  messages=[
      {"role": "system", "content": "You are a helpful math tutor. Guide the user through the solution step by step."},
      {"role": "user", "content": "how can I solve 8x + 7 = -23"}
  ],
  response_format=MathResponse
)
```

```javascript
const completion = await openai.beta.chat.completions.parse({
model: "gpt-4o-2024-08-06",
messages: [
  { role: "system", content: "You are a helpful math tutor. Guide the user through the solution step by step." },
  { role: "user", content: "how can I solve 8x + 7 = -23" },
],
response_format: zodResponseFormat(MathResponse, "math_response"),
});
```

Step 3: Handle edge cases

In some cases, the model might not generate a valid response that matches the provided JSON schema.

This can happen in the case of a refusal, if the model refuses to answer for safety reasons, or if for example you reach a max tokens limit and the response is incomplete.

```python
try:
  completion = client.beta.chat.completions.parse(
      model="gpt-4o-2024-08-06",
      messages=[
          {"role": "system", "content": "You are a helpful math tutor. Guide the user through the solution step by step."},
          {"role": "user", "content": "how can I solve 8x + 7 = -23"}
      ],
      response_format=MathResponse,
      max_tokens=50
  )
  math_response = completion.choices[0].message
  if math_response.parsed:
      print(math_response.parsed)
  elif math_response.refusal:
      # handle refusal
      print(math_response.refusal)
except Exception as e:
  # Handle edge cases
  if type(e) == openai.LengthFinishReasonError:
      # Retry with a higher max tokens
      print("Too many tokens: ", e)
      pass
  else:
      # Handle other exceptions
      print(e)
      pass
```

```javascript
try {
const completion = await openai.beta.chat.completions.parse({
  model: "gpt-4o-2024-08-06",
  messages: [
    {
      role: "system",
      content:
        "You are a helpful math tutor. Guide the user through the solution step by step.",
    },
    { role: "user", content: "how can I solve 8x + 7 = -23" },
  ],
  response_format: zodResponseFormat(MathResponse, "math_response"),
  max_tokens: 50,
});

const math_response = completion.choices[0].message;
console.log(math_response);
if (math_response.parsed) {
  console.log(math_response.parsed);
} else if (math_response.refusal) {
  // handle refusal
  console.log(math_response.refusal);
}
} catch (e) {
// Handle edge cases
if (e.constructor.name == "LengthFinishReasonError") {
  // Retry with a higher max tokens
  console.log("Too many tokens: ", e.message);
} else {
  // Handle other exceptions
  console.log("An error occurred: ", e.message);
}
}
```

Step 4: Use the generated structured data in a type-safe way

When using the SDK, you can use the `parsed` attribute to access the parsed JSON response as an object. This object will be of the type you defined in the `response_format` parameter.

```python
math_response = completion.choices[0].message.parsed
print(math_response.steps)
print(math_response.final_answer)
```

```javascript
const math_response = completion.choices[0].message.parsed;
console.log(math_response.steps);
console.log(math_response.final_answer);
```

### 

Refusals with Structured Outputs

When using Structured Outputs with user-generated input, OpenAI models may occasionally refuse to fulfill the request for safety reasons. Since a refusal does not necessarily follow the schema you have supplied in `response_format`, the API response will include a new field called `refusal` to indicate that the model refused to fulfill the request.

When the `refusal` property appears in your output object, you might present the refusal in your UI, or include conditional logic in code that consumes the response to handle the case of a refused request.

```python
class Step(BaseModel):
  explanation: str
  output: str

class MathReasoning(BaseModel):
  steps: list[Step]
  final_answer: str

completion = client.beta.chat.completions.parse(
  model="gpt-4o-2024-08-06",
  messages=[
      {"role": "system", "content": "You are a helpful math tutor. Guide the user through the solution step by step."},
      {"role": "user", "content": "how can I solve 8x + 7 = -23"}
  ],
  response_format=MathReasoning,
)

math_reasoning = completion.choices[0].message

# If the model refuses to respond, you will get a refusal message
if (math_reasoning.refusal):
  print(math_reasoning.refusal)
else:
  print(math_reasoning.parsed)
```

```javascript
const Step = z.object({
explanation: z.string(),
output: z.string(),
});

const MathReasoning = z.object({
steps: z.array(Step),
final_answer: z.string(),
});

const completion = await openai.beta.chat.completions.parse({
model: "gpt-4o-2024-08-06",
messages: [
  { role: "system", content: "You are a helpful math tutor. Guide the user through the solution step by step." },
  { role: "user", content: "how can I solve 8x + 7 = -23" },
],
response_format: zodResponseFormat(MathReasoning, "math_reasoning"),
});

const math_reasoning = completion.choices[0].message

// If the model refuses to respond, you will get a refusal message
if (math_reasoning.refusal) {
console.log(math_reasoning.refusal);
} else {
console.log(math_reasoning.parsed);
}
```

The API response from a refusal will look something like this:

```json
{
"id": "chatcmpl-9nYAG9LPNonX8DAyrkwYfemr3C8HC",
"object": "chat.completion",
"created": 1721596428,
"model": "gpt-4o-2024-08-06",
"choices": [
  {
  "index": 0,
  "message": {
          "role": "assistant",
          "refusal": "I'm sorry, I cannot assist with that request."
  },
  "logprobs": null,
  "finish_reason": "stop"
}
],
"usage": {
    "prompt_tokens": 81,
    "completion_tokens": 11,
    "total_tokens": 92,
    "completion_tokens_details": {
      "reasoning_tokens": 0,
      "accepted_prediction_tokens": 0,
      "rejected_prediction_tokens": 0
    }
},
"system_fingerprint": "fp_3407719c7f"
}
```

### 

Tips and best practices

#### Handling user-generated input

If your application is using user-generated input, make sure your prompt includes instructions on how to handle situations where the input cannot result in a valid response.

The model will always try to adhere to the provided schema, which can result in hallucinations if the input is completely unrelated to the schema.

You could include language in your prompt to specify that you want to return empty parameters, or a specific sentence, if the model detects that the input is incompatible with the task.

#### Handling mistakes

Structured Outputs can still contain mistakes. If you see mistakes, try adjusting your instructions, providing examples in the system instructions, or splitting tasks into simpler subtasks. Refer to the [prompt engineering guide](/docs/guides/prompt-engineering) for more guidance on how to tweak your inputs.

#### Avoid JSON schema divergence

To prevent your JSON Schema and corresponding types in your programming language from diverging, we strongly recommend using the native Pydantic/zod sdk support.

If you prefer to specify the JSON schema directly, you could add CI rules that flag when either the JSON schema or underlying data objects are edited, or add a CI step that auto-generates the JSON Schema from type definitions (or vice-versa).

Streaming
---------

You can use streaming to process model responses or function call arguments as they are being generated, and parse them as structured data.

That way, you don't have to wait for the entire response to complete before handling it. This is particularly useful if you would like to display JSON fields one by one, or handle function call arguments as soon as they are available.

We recommend relying on the SDKs to handle streaming with Structured Outputs. You can find an example of how to stream function call arguments without the SDK `stream` helper in the [function calling guide](/docs/guides/function-calling#advanced-usage).

Here is how you can stream a model response with the `stream` helper:

```python
from typing import List
from pydantic import BaseModel
from openai import OpenAI

class EntitiesModel(BaseModel):
  attributes: List[str]
  colors: List[str]
  animals: List[str]

client = OpenAI()

with client.beta.chat.completions.stream(
  model="gpt-4o",
  messages=[
      {"role": "system", "content": "Extract entities from the input text"},
      {
          "role": "user",
          "content": "The quick brown fox jumps over the lazy dog with piercing blue eyes",
      },
  ],
  response_format=EntitiesModel,
) as stream:
  for event in stream:
      if event.type == "content.delta":
          if event.parsed is not None:
              # Print the parsed data as JSON
              print("content.delta parsed:", event.parsed)
      elif event.type == "content.done":
          print("content.done")
      elif event.type == "error":
          print("Error in stream:", event.error)

final_completion = stream.get_final_completion()
print("Final completion:", final_completion)
```

```js
import OpenAI from "openai";
import { zodResponseFormat } from "openai/helpers/zod";
import { z } from "zod";
export const openai = new OpenAI();

const EntitiesSchema = z.object({
attributes: z.array(z.string()),
colors: z.array(z.string()),
animals: z.array(z.string()),
});

const stream = openai.beta.chat.completions
.stream({
  model: "gpt-4o",
  messages: [
    { role: "system", content: "Extract entities from the input text" },
    {
      role: "user",
      content:
        "The quick brown fox jumps over the lazy dog with piercing blue eyes",
    },
  ],
  response_format: zodResponseFormat(EntitiesSchema, "entities"),
})
.on("refusal.done", () => console.log("request refused"))
.on("content.delta", ({ snapshot, parsed }) => {
  console.log("content:", snapshot);
  console.log("parsed:", parsed);
  console.log();
})
.on("content.done", (props) => {
  console.log(props);
});

await stream.done();

const finalCompletion = await stream.finalChatCompletion();

console.log(finalCompletion);
```

You can also use the `stream` helper to parse function call arguments:

```python
from pydantic import BaseModel
import openai
from openai import OpenAI

class GetWeather(BaseModel):
  city: str
  country: str

client = OpenAI()

with client.beta.chat.completions.stream(
  model="gpt-4o",
  messages=[
      {
          "role": "user",
          "content": "What's the weather like in SF and London?",
      },
  ],
  tools=[
      openai.pydantic_function_tool(GetWeather, name="get_weather"),
  ],
  parallel_tool_calls=True,
) as stream:
  for event in stream:
      if event.type == "tool_calls.function.arguments.delta" or event.type == "tool_calls.function.arguments.done":
          print(event)

print(stream.get_final_completion())
```

```js
import { zodFunction } from "openai/helpers/zod";
import OpenAI from "openai/index";
import { z } from "zod";

const GetWeatherArgs = z.object({
city: z.string(),
country: z.string(),
});

const client = new OpenAI();

const stream = client.beta.chat.completions
.stream({
  model: "gpt-4o",
  messages: [
    {
      role: "user",
      content: "What's the weather like in SF and London?",
    },
  ],
  tools: [zodFunction({ name: "get_weather", parameters: GetWeatherArgs })],
})
.on("tool_calls.function.arguments.delta", (props) =>
  console.log("tool_calls.function.arguments.delta", props)
)
.on("tool_calls.function.arguments.done", (props) =>
  console.log("tool_calls.function.arguments.done", props)
)
.on("refusal.delta", ({ delta }) => {
  process.stdout.write(delta);
})
.on("refusal.done", () => console.log("request refused"));

const completion = await stream.finalChatCompletion();

console.log("final completion:", completion);
```

Supported schemas
-----------------

Structured Outputs supports a subset of the [JSON Schema](https://json-schema.org/docs) language.

#### Supported types

The following types are supported for Structured Outputs:

*   String
*   Number
*   Boolean
*   Integer
*   Object
*   Array
*   Enum
*   anyOf

#### Root objects must not be `anyOf`

Note that the root level object of a schema must be an object, and not use `anyOf`. A pattern that appears in Zod (as one example) is using a discriminated union, which produces an `anyOf` at the top level. So code such as the following won't work:

```javascript
import { z } from 'zod';
import { zodResponseFormat } from 'openai/helpers/zod';

const BaseResponseSchema = z.object({ /* ... */ });
const UnsuccessfulResponseSchema = z.object({ /* ... */ });

const finalSchema = z.discriminatedUnion('status', [
  BaseResponseSchema,
  UnsuccessfulResponseSchema,
]);

// Invalid JSON Schema for Structured Outputs
const json = zodResponseFormat(finalSchema, 'final_schema');
```

#### All fields must be `required`

To use Structured Outputs, all fields or function parameters must be specified as `required`.

```json
{
  "name": "get_weather",
  "description": "Fetches the weather in the given location",
  "strict": true,
  "parameters": {
      "type": "object",
      "properties": {
          "location": {
              "type": "string",
              "description": "The location to get the weather for"
          },
          "unit": {
              "type": "string",
              "description": "The unit to return the temperature in",
              "enum": ["F", "C"]
          }
      },
      "additionalProperties": false,
      "required": ["location", "unit"]
  }
}
```

Although all fields must be required (and the model will return a value for each parameter), it is possible to emulate an optional parameter by using a union type with `null`.

```json
{
  "name": "get_weather",
  "description": "Fetches the weather in the given location",
  "strict": true,
  "parameters": {
      "type": "object",
      "properties": {
          "location": {
              "type": "string",
              "description": "The location to get the weather for"
          },
          "unit": {
              "type": ["string", "null"],
              "description": "The unit to return the temperature in",
              "enum": ["F", "C"]
          }
      },
      "additionalProperties": false,
      "required": [
          "location", "unit"
      ]
  }
}
```

#### Objects have limitations on nesting depth and size

A schema may have up to 100 object properties total, with up to 5 levels of nesting.

#### Limitations on total string size

In a schema, total string length of all property names, definition names, enum values, and const values cannot exceed 15,000 characters.

#### Limitations on enum size

A schema may have up to 500 enum values across all enum properties.

For a single enum property with string values, the total string length of all enum values cannot exceed 7,500 characters when there are more than 250 enum values.

#### `additionalProperties: false` must always be set in objects

`additionalProperties` controls whether it is allowable for an object to contain additional keys / values that were not defined in the JSON Schema.

Structured Outputs only supports generating specified keys / values, so we require developers to set `additionalProperties: false` to opt into Structured Outputs.

```json
{
  "name": "get_weather",
  "description": "Fetches the weather in the given location",
  "strict": true,
  "schema": {
      "type": "object",
      "properties": {
          "location": {
              "type": "string",
              "description": "The location to get the weather for"
          },
          "unit": {
              "type": "string",
              "description": "The unit to return the temperature in",
              "enum": ["F", "C"]
          }
      },
      "additionalProperties": false,
      "required": [
          "location", "unit"
      ]
  }
}
```

#### Key ordering

When using Structured Outputs, outputs will be produced in the same order as the ordering of keys in the schema.

#### Some type-specific keywords are not yet supported

Notable keywords not supported include:

*   **For strings:** `minLength`, `maxLength`, `pattern`, `format`
*   **For numbers:** `minimum`, `maximum`, `multipleOf`
*   **For objects:** `patternProperties`, `unevaluatedProperties`, `propertyNames`, `minProperties`, `maxProperties`
*   **For arrays:** `unevaluatedItems`, `contains`, `minContains`, `maxContains`, `minItems`, `maxItems`, `uniqueItems`

If you turn on Structured Outputs by supplying `strict: true` and call the API with an unsupported JSON Schema, you will receive an error.

#### For `anyOf`, the nested schemas must each be a valid JSON Schema per this subset

Here's an example supported anyOf schema:

```json
{
  "type": "object",
  "properties": {
      "item": {
          "anyOf": [
              {
                  "type": "object",
                  "description": "The user object to insert into the database",
                  "properties": {
                      "name": {
                          "type": "string",
                          "description": "The name of the user"
                      },
                      "age": {
                          "type": "number",
                          "description": "The age of the user"
                      }
                  },
                  "additionalProperties": false,
                  "required": [
                      "name",
                      "age"
                  ]
              },
              {
                  "type": "object",
                  "description": "The address object to insert into the database",
                  "properties": {
                      "number": {
                          "type": "string",
                          "description": "The number of the address. Eg. for 123 main st, this would be 123"
                      },
                      "street": {
                          "type": "string",
                          "description": "The street name. Eg. for 123 main st, this would be main st"
                      },
                      "city": {
                          "type": "string",
                          "description": "The city of the address"
                      }
                  },
                  "additionalProperties": false,
                  "required": [
                      "number",
                      "street",
                      "city"
                  ]
              }
          ]
      }
  },
  "additionalProperties": false,
  "required": [
      "item"
  ]
}
```

#### Definitions are supported

You can use definitions to define subschemas which are referenced throughout your schema. The following is a simple example.

```json
{
  "type": "object",
  "properties": {
      "steps": {
          "type": "array",
          "items": {
              "$ref": "#/$defs/step"
          }
      },
      "final_answer": {
          "type": "string"
      }
  },
  "$defs": {
      "step": {
          "type": "object",
          "properties": {
              "explanation": {
                  "type": "string"
              },
              "output": {
                  "type": "string"
              }
          },
          "required": [
              "explanation",
              "output"
          ],
          "additionalProperties": false
      }
  },
  "required": [
      "steps",
      "final_answer"
  ],
  "additionalProperties": false
}
```

#### Recursive schemas are supported

Sample recursive schema using `#` to indicate root recursion.

```json
{
  "name": "ui",
  "description": "Dynamically generated UI",
  "strict": true,
  "schema": {
      "type": "object",
      "properties": {
          "type": {
              "type": "string",
              "description": "The type of the UI component",
              "enum": ["div", "button", "header", "section", "field", "form"]
          },
          "label": {
              "type": "string",
              "description": "The label of the UI component, used for buttons or form fields"
          },
          "children": {
              "type": "array",
              "description": "Nested UI components",
              "items": {
                  "$ref": "#"
              }
          },
          "attributes": {
              "type": "array",
              "description": "Arbitrary attributes for the UI component, suitable for any element",
              "items": {
                  "type": "object",
                  "properties": {
                      "name": {
                          "type": "string",
                          "description": "The name of the attribute, for example onClick or className"
                      },
                      "value": {
                          "type": "string",
                          "description": "The value of the attribute"
                      }
                  },
                  "additionalProperties": false,
                  "required": ["name", "value"]
              }
          }
      },
      "required": ["type", "label", "children", "attributes"],
      "additionalProperties": false
  }
}
```

Sample recursive schema using explicit recursion:

```json
{
  "type": "object",
  "properties": {
      "linked_list": {
          "$ref": "#/$defs/linked_list_node"
      }
  },
  "$defs": {
      "linked_list_node": {
          "type": "object",
          "properties": {
              "value": {
                  "type": "number"
              },
              "next": {
                  "anyOf": [
                      {
                          "$ref": "#/$defs/linked_list_node"
                      },
                      {
                          "type": "null"
                      }
                  ]
              }
          },
          "additionalProperties": false,
          "required": [
              "next",
              "value"
          ]
      }
  },
  "additionalProperties": false,
  "required": [
      "linked_list"
  ]
}
```

JSON mode
---------

JSON mode is a more basic version of the Structured Outputs feature. While JSON mode ensures that model output is valid JSON, Structured Outputs reliably matches the model's output to the schema you specify. We recommend you use Structured Outputs if it is supported for your use case.

When JSON mode is turned on, the model's output is ensured to be valid JSON, except for in some edge cases that you should detect and handle appropriately.

To turn on JSON mode with the Chat Completions or Assistants API you can set the `response_format` to `{ "type": "json_object" }`. If you are using function calling, JSON mode is always turned on.

Important notes:

*   When using JSON mode, you must always instruct the model to produce JSON via some message in the conversation, for example via your system message. If you don't include an explicit instruction to generate JSON, the model may generate an unending stream of whitespace and the request may run continually until it reaches the token limit. To help ensure you don't forget, the API will throw an error if the string "JSON" does not appear somewhere in the context.
*   JSON mode will not guarantee the output matches any specific schema, only that it is valid and parses without errors. You should use Structured Outputs to ensure it matches your schema, or if that is not possible, you should use a validation library and potentially retries to ensure that the output matches your desired schema.
*   Your application must detect and handle the edge cases that can result in the model output not being a complete JSON object (see below)

Handling edge cases

```javascript
const we_did_not_specify_stop_tokens = true;

try {
  const response = await openai.chat.completions.create({
    model: "gpt-3.5-turbo-0125",
    messages: [
      {
        role: "system",
        content: "You are a helpful assistant designed to output JSON.",
      },
      { role: "user", content: "Who won the world series in 2020? Please respond in the format {winner: ...}" },
    ],
    response_format: { type: "json_object" },
  });

  // Check if the conversation was too long for the context window, resulting in incomplete JSON 
  if (response.choices[0].message.finish_reason === "length") {
    // your code should handle this error case
  }

  // Check if the OpenAI safety system refused the request and generated a refusal instead
  if (response.choices[0].message[0].refusal) {
    // your code should handle this error case
    // In this case, the .content field will contain the explanation (if any) that the model generated for why it is refusing
    console.log(response.choices[0].message[0].refusal)
  }

  // Check if the model's output included restricted content, so the generation of JSON was halted and may be partial
  if (response.choices[0].message.finish_reason === "content_filter") {
    // your code should handle this error case
  }

  if (response.choices[0].message.finish_reason === "stop") {
    // In this case the model has either successfully finished generating the JSON object according to your schema, or the model generated one of the tokens you provided as a "stop token"

    if (we_did_not_specify_stop_tokens) {
      // If you didn't specify any stop tokens, then the generation is complete and the content key will contain the serialized JSON object
      // This will parse successfully and should now contain  {"winner": "Los Angeles Dodgers"}
      console.log(JSON.parse(response.choices[0].message.content))
    } else {
      // Check if the response.choices[0].message.content ends with one of your stop tokens and handle appropriately
    }
  }
} catch (e) {
  // Your code should handle errors here, for example a network error calling the API
  console.error(e)
}
```

```python
we_did_not_specify_stop_tokens = True

try:
    response = client.chat.completions.create(
        model="gpt-3.5-turbo-0125",
        messages=[
            {"role": "system", "content": "You are a helpful assistant designed to output JSON."},
            {"role": "user", "content": "Who won the world series in 2020? Please respond in the format {winner: ...}"}
        ],
        response_format={"type": "json_object"}
    )

    # Check if the conversation was too long for the context window, resulting in incomplete JSON 
    if response.choices[0].message.finish_reason == "length":
        # your code should handle this error case
        pass

    # Check if the OpenAI safety system refused the request and generated a refusal instead
    if response.choices[0].message[0].get("refusal"):
        # your code should handle this error case
        # In this case, the .content field will contain the explanation (if any) that the model generated for why it is refusing
        print(response.choices[0].message[0]["refusal"])

    # Check if the model's output included restricted content, so the generation of JSON was halted and may be partial
    if response.choices[0].message.finish_reason == "content_filter":
        # your code should handle this error case
        pass

    if response.choices[0].message.finish_reason == "stop":
        # In this case the model has either successfully finished generating the JSON object according to your schema, or the model generated one of the tokens you provided as a "stop token"

        if we_did_not_specify_stop_tokens:
            # If you didn't specify any stop tokens, then the generation is complete and the content key will contain the serialized JSON object
            # This will parse successfully and should now contain  "{"winner": "Los Angeles Dodgers"}"
            print(response.choices[0].message.content)
        else:
            # Check if the response.choices[0].message.content ends with one of your stop tokens and handle appropriately
            pass
except Exception as e:
    # Your code should handle errors here, for example a network error calling the API
    print(e)
```

Resources
---------

To learn more about Structured Outputs, we recommend browsing the following resources:

*   Check out our [introductory cookbook](https://cookbook.openai.com/examples/structured_outputs_intro) on Structured Outputs
*   Learn [how to build multi-agent systems](https://cookbook.openai.com/examples/structured_outputs_multi_agent) with Structured Outputs

Was this page useful?

Speech to text
==============

Learn how to turn audio into text.

Overview
--------

The Audio API provides two speech to text endpoints, `transcriptions` and `translations`, based on our state-of-the-art open source large-v2 [Whisper model](https://openai.com/blog/whisper/). They can be used to:

*   Transcribe audio into whatever language the audio is in.
*   Translate and transcribe the audio into english.

File uploads are currently limited to 25 MB and the following input file types are supported: `mp3`, `mp4`, `mpeg`, `mpga`, `m4a`, `wav`, and `webm`.

Quickstart
----------

### Transcriptions

The transcriptions API takes as input the audio file you want to transcribe and the desired output file format for the transcription of the audio. We currently support multiple input and output file formats.

Transcribe audio

```javascript
import fs from "fs";
import OpenAI from "openai";

const openai = new OpenAI();

const transcription = await openai.audio.transcriptions.create({
  file: fs.createReadStream("/path/to/file/audio.mp3"),
  model: "whisper-1",
});

console.log(transcription.text);
```

```python
from openai import OpenAI
client = OpenAI()

audio_file= open("/path/to/file/audio.mp3", "rb")
transcription = client.audio.transcriptions.create(
    model="whisper-1", 
    file=audio_file
)

print(transcription.text)
```

```bash
curl --request POST \
  --url https://api.openai.com/v1/audio/transcriptions \
  --header "Authorization: Bearer $OPENAI_API_KEY" \
  --header 'Content-Type: multipart/form-data' \
  --form file=@/path/to/file/audio.mp3 \
  --form model=whisper-1
```

By default, the response type will be json with the raw text included.

{ "text": "Imagine the wildest idea that you've ever had, and you're curious about how it might scale to something that's a 100, a 1,000 times bigger. .... }

The Audio API also allows you to set additional parameters in a request. For example, if you want to set the `response_format` as `text`, your request would look like the following:

Additional options

```javascript
import fs from "fs";
import OpenAI from "openai";

const openai = new OpenAI();

const transcription = await openai.audio.transcriptions.create({
  file: fs.createReadStream("/path/to/file/speech.mp3"),
  model: "whisper-1",
  response_format: "text",
});

console.log(transcription.text);
```

```python
from openai import OpenAI
client = OpenAI()

audio_file = open("/path/to/file/speech.mp3", "rb")
transcription = client.audio.transcriptions.create(
    model="whisper-1", 
    file=audio_file, 
    response_format="text"
)

print(transcription.text)
```

```bash
curl --request POST \
  --url https://api.openai.com/v1/audio/transcriptions \
  --header "Authorization: Bearer $OPENAI_API_KEY" \
  --header 'Content-Type: multipart/form-data' \
  --form file=@/path/to/file/speech.mp3 \
  --form model=whisper-1 \
  --form response_format=text
```

The [API Reference](/docs/api-reference/audio) includes the full list of available parameters.

### Translations

The translations API takes as input the audio file in any of the supported languages and transcribes, if necessary, the audio into English. This differs from our /Transcriptions endpoint since the output is not in the original input language and is instead translated to English text.

Translate audio

```javascript
import fs from "fs";
import OpenAI from "openai";

const openai = new OpenAI();

const transcription = await openai.audio.translations.create({
  file: fs.createReadStream("/path/to/file/german.mp3"),
  model: "whisper-1",
});

console.log(transcription.text);
```

```python
from openai import OpenAI
client = OpenAI()

audio_file = open("/path/to/file/german.mp3", "rb")
transcription = client.audio.translations.create(
    model="whisper-1", 
    file=audio_file,
)

print(transcription.text)
```

```bash
curl --request POST \
  --url https://api.openai.com/v1/audio/translations \
  --header "Authorization: Bearer $OPENAI_API_KEY" \
  --header 'Content-Type: multipart/form-data' \
  --form file=@/path/to/file/german.mp3 \
  --form model=whisper-1 \
```

In this case, the inputted audio was german and the outputted text looks like:

Hello, my name is Wolfgang and I come from Germany. Where are you heading today?

We only support translation into English at this time.

Supported languages
-------------------

We currently [support the following languages](https://github.com/openai/whisper#available-models-and-languages) through both the `transcriptions` and `translations` endpoint:

Afrikaans, Arabic, Armenian, Azerbaijani, Belarusian, Bosnian, Bulgarian, Catalan, Chinese, Croatian, Czech, Danish, Dutch, English, Estonian, Finnish, French, Galician, German, Greek, Hebrew, Hindi, Hungarian, Icelandic, Indonesian, Italian, Japanese, Kannada, Kazakh, Korean, Latvian, Lithuanian, Macedonian, Malay, Marathi, Maori, Nepali, Norwegian, Persian, Polish, Portuguese, Romanian, Russian, Serbian, Slovak, Slovenian, Spanish, Swahili, Swedish, Tagalog, Tamil, Thai, Turkish, Ukrainian, Urdu, Vietnamese, and Welsh.

While the underlying model was trained on 98 languages, we only list the languages that exceeded <50% [word error rate](https://en.wikipedia.org/wiki/Word_error_rate) (WER) which is an industry standard benchmark for speech to text model accuracy. The model will return results for languages not listed above but the quality will be low.

Timestamps
----------

By default, the Whisper API will output a transcript of the provided audio in text. The [`timestamp_granularities[]` parameter](/docs/api-reference/audio/createTranscription#audio-createtranscription-timestamp_granularities) enables a more structured and timestamped json output format, with timestamps at the segment, word level, or both. This enables word-level precision for transcripts and video edits, which allows for the removal of specific frames tied to individual words.

Timestamp options

```javascript
import fs from "fs";
import OpenAI from "openai";

const openai = new OpenAI();

const transcription = await openai.audio.transcriptions.create({
  file: fs.createReadStream("audio.mp3"),
  model: "whisper-1",
  response_format: "verbose_json",
  timestamp_granularities: ["word"]
});

console.log(transcription.words);
```

```python
from openai import OpenAI
client = OpenAI()

audio_file = open("/path/to/file/speech.mp3", "rb")
transcription = client.audio.transcriptions.create(
    file=audio_file,
    model="whisper-1",
    response_format="verbose_json",
    timestamp_granularities=["word"]
)

print(transcription.words)
```

```bash
curl https://api.openai.com/v1/audio/transcriptions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: multipart/form-data" \
  -F file="@/path/to/file/audio.mp3" \
  -F "timestamp_granularities[]=word" \
  -F model="whisper-1" \
  -F response_format="verbose_json"
```

Longer inputs
-------------

By default, the Whisper API only supports files that are less than 25 MB. If you have an audio file that is longer than that, you will need to break it up into chunks of 25 MB's or less or used a compressed audio format. To get the best performance, we suggest that you avoid breaking the audio up mid-sentence as this may cause some context to be lost.

One way to handle this is to use the [PyDub open source Python package](https://github.com/jiaaro/pydub) to split the audio:

```python
from pydub import AudioSegment

song = AudioSegment.from_mp3("good_morning.mp3")

# PyDub handles time in milliseconds
ten_minutes = 10 * 60 * 1000

first_10_minutes = song[:ten_minutes]

first_10_minutes.export("good_morning_10.mp3", format="mp3")
```

_OpenAI makes no guarantees about the usability or security of 3rd party software like PyDub._

Prompting
---------

You can use a [prompt](/docs/api-reference/audio/createTranscription#audio/createTranscription-prompt) to improve the quality of the transcripts generated by the Whisper API. The model will try to match the style of the prompt, so it will be more likely to use capitalization and punctuation if the prompt does too. However, the current prompting system is much more limited than our other language models and only provides limited control over the generated audio. Here are some examples of how prompting can help in different scenarios:

1.  Prompts can be very helpful for correcting specific words or acronyms that the model may misrecognize in the audio. For example, the following prompt improves the transcription of the words DALL·E and GPT-3, which were previously written as "GDP 3" and "DALI": "The transcript is about OpenAI which makes technology like DALL·E, GPT-3, and ChatGPT with the hope of one day building an AGI system that benefits all of humanity"
2.  To preserve the context of a file that was split into segments, you can prompt the model with the transcript of the preceding segment. This will make the transcript more accurate, as the model will use the relevant information from the previous audio. The model will only consider the final 224 tokens of the prompt and ignore anything earlier. For multilingual inputs, Whisper uses a custom tokenizer. For English only inputs, it uses the standard GPT-2 tokenizer which are both accessible through the open source [Whisper Python package](https://github.com/openai/whisper/blob/main/whisper/tokenizer.py#L361).
3.  Sometimes the model might skip punctuation in the transcript. You can avoid this by using a simple prompt that includes punctuation: "Hello, welcome to my lecture."
4.  The model may also leave out common filler words in the audio. If you want to keep the filler words in your transcript, you can use a prompt that contains them: "Umm, let me think like, hmm... Okay, here's what I'm, like, thinking."
5.  Some languages can be written in different ways, such as simplified or traditional Chinese. The model might not always use the writing style that you want for your transcript by default. You can improve this by using a prompt in your preferred writing style.

Improving reliability
---------------------

As we explored in the prompting section, one of the most common challenges faced when using Whisper is the model often does not recognize uncommon words or acronyms. To address this, we have highlighted different techniques which improve the reliability of Whisper in these cases:

Using the prompt parameter

The first method involves using the optional prompt parameter to pass a dictionary of the correct spellings.

Since it wasn't trained using instruction-following techniques, Whisper operates more like a base GPT model. It's important to keep in mind that Whisper only considers the first 244 tokens of the prompt.

Prompt parameter

```javascript
import fs from "fs";
import OpenAI from "openai";

const openai = new OpenAI();

const transcription = await openai.audio.transcriptions.create({
  file: fs.createReadStream("/path/to/file/speech.mp3"),
  model: "whisper-1",
  response_format: "text",
  prompt:"ZyntriQix, Digique Plus, CynapseFive, VortiQore V8, EchoNix Array, OrbitalLink Seven, DigiFractal Matrix, PULSE, RAPT, B.R.I.C.K., Q.U.A.R.T.Z., F.L.I.N.T.",
});

console.log(transcription.text);
```

```python
from openai import OpenAI
client = OpenAI()

audio_file = open("/path/to/file/speech.mp3", "rb")
transcription = client.audio.transcriptions.create(
    model="whisper-1", 
    file=audio_file, 
    response_format="text",
    prompt="ZyntriQix, Digique Plus, CynapseFive, VortiQore V8, EchoNix Array, OrbitalLink Seven, DigiFractal Matrix, PULSE, RAPT, B.R.I.C.K., Q.U.A.R.T.Z., F.L.I.N.T."
)

print(transcription.text)
```

While it will increase reliability, this technique is limited to only 244 characters so your list of SKUs would need to be relatively small in order for this to be a scalable solution.

Post-processing with GPT-4

The second method involves a post-processing step using GPT-4 or GPT-3.5-Turbo.

We start by providing instructions for GPT-4 through the `system_prompt` variable. Similar to what we did with the prompt parameter earlier, we can define our company and product names.

Post-processing

```javascript
const systemPrompt = `
You are a helpful assistant for the company ZyntriQix. Your task is 
to correct any spelling discrepancies in the transcribed text. Make 
sure that the names of the following products are spelled correctly: 
ZyntriQix, Digique Plus, CynapseFive, VortiQore V8, EchoNix Array, 
OrbitalLink Seven, DigiFractal Matrix, PULSE, RAPT, B.R.I.C.K., 
Q.U.A.R.T.Z., F.L.I.N.T. Only add necessary punctuation such as 
periods, commas, and capitalization, and use only the context provided.
`;

const transcript = await transcribe(audioFile);
const completion = await openai.chat.completions.create({
  model: "gpt-4o",
  temperature: temperature,
  messages: [
    {
      role: "system",
      content: systemPrompt
    },
    {
      role: "user",
      content: transcript
    }
  ]
});

console.log(completion.choices[0].message.content);
```

```python
system_prompt = """
You are a helpful assistant for the company ZyntriQix. Your task is to correct 
any spelling discrepancies in the transcribed text. Make sure that the names of 
the following products are spelled correctly: ZyntriQix, Digique Plus, 
CynapseFive, VortiQore V8, EchoNix Array, OrbitalLink Seven, DigiFractal 
Matrix, PULSE, RAPT, B.R.I.C.K., Q.U.A.R.T.Z., F.L.I.N.T. Only add necessary 
punctuation such as periods, commas, and capitalization, and use only the 
context provided.
"""

def generate_corrected_transcript(temperature, system_prompt, audio_file):
    response = client.chat.completions.create(
        model="gpt-4o",
        temperature=temperature,
        messages=[
            {
                "role": "system",
                "content": system_prompt
            },
            {
                "role": "user",
                "content": transcribe(audio_file, "")
            }
        ]
    )
    return completion.choices[0].message.content
corrected_text = generate_corrected_transcript(
    0, system_prompt, fake_company_filepath
)
```

If you try this on your own audio file, you can see that GPT-4 manages to correct many misspellings in the transcript. Due to its larger context window, this method might be more scalable than using Whisper's prompt parameter and is more reliable since GPT-4 can be instructed and guided in ways that aren't possible with Whisper given the lack of instruction following.

Was this page useful?

Text generation
===============

Learn how to generate text from a prompt.

OpenAI provides simple APIs to use a [large language model](/docs/models) to generate text from a prompt, as you might using [ChatGPT](https://chatgpt.com). These models have been trained on vast quantities of data to understand multimedia inputs and natural language instructions. From these [prompts](/docs/guides/prompt-engineering), models can generate almost any kind of text response, like code, mathematical equations, structured JSON data, or human-like prose.

Quickstart
----------

To generate text, you can use the [chat completions endpoint](/docs/api-reference/chat/) in the REST API, as seen in the examples below. You can either use the [REST API](/docs/api-reference) from the HTTP client of your choice, or use one of OpenAI's [official SDKs](/docs/libraries) for your preferred programming language.

Generate prose

Create a human-like response to a prompt

```javascript
import OpenAI from "openai";
const openai = new OpenAI();

const completion = await openai.chat.completions.create({
    model: "gpt-4o",
    messages: [
        { role: "developer", content: "You are a helpful assistant." },
        {
            role: "user",
            content: "Write a haiku about recursion in programming.",
        },
    ],
});

console.log(completion.choices[0].message);
```

```python
from openai import OpenAI
client = OpenAI()

completion = client.chat.completions.create(
    model="gpt-4o",
    messages=[
        {"role": "developer", "content": "You are a helpful assistant."},
        {
            "role": "user",
            "content": "Write a haiku about recursion in programming."
        }
    ]
)

print(completion.choices[0].message)
```

```bash
curl "https://api.openai.com/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d '{
        "model": "gpt-4o",
        "messages": [
            {
                "role": "developer",
                "content": "You are a helpful assistant."
            },
            {
                "role": "user",
                "content": "Write a haiku about recursion in programming."
            }
        ]
    }'
```

Analyze an image

Describe the contents of an image

```javascript
import OpenAI from "openai";
const openai = new OpenAI();

const completion = await openai.chat.completions.create({
    model: "gpt-4o",
    messages: [
        {
            role: "user",
            content: [
                { type: "text", text: "What's in this image?" },
                {
                    type: "image_url",
                    image_url: {
                        "url": "https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/Gfp-wisconsin-madison-the-nature-boardwalk.jpg/2560px-Gfp-wisconsin-madison-the-nature-boardwalk.jpg",
                    },
                }
            ],
        },
    ],
});

console.log(completion.choices[0].message);
```

```python
from openai import OpenAI

client = OpenAI()

completion = client.chat.completions.create(
    model="gpt-4o",
    messages=[
        {
            "role": "user",
            "content": [
                {"type": "text", "text": "What's in this image?"},
                {
                    "type": "image_url",
                    "image_url": {
                        "url": "https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/Gfp-wisconsin-madison-the-nature-boardwalk.jpg/2560px-Gfp-wisconsin-madison-the-nature-boardwalk.jpg",
                    }
                },
            ],
        }
    ],
)

print(completion.choices[0].message)
```

```bash
curl https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{
    "model": "gpt-4o",
    "messages": [
      {
        "role": "user",
        "content": [
          {
            "type": "text",
            "text": "What is in this image?"
          },
          {
            "type": "image_url",
            "image_url": {
              "url": "https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/Gfp-wisconsin-madison-the-nature-boardwalk.jpg/2560px-Gfp-wisconsin-madison-the-nature-boardwalk.jpg"
            }
          }
        ]
      }
    ]
  }'
```

Generate JSON data

Generate JSON data based on a JSON Schema

```javascript
import OpenAI from "openai";
const openai = new OpenAI();

const completion = await openai.chat.completions.create({
    model: "gpt-4o-2024-08-06",
    messages: [
        { role: "developer", content: "You extract email addresses into JSON data." },
        {
            role: "user",
            content: "Feeling stuck? Send a message to help@mycompany.com.",
        },
    ],
    response_format: {
        // See /docs/guides/structured-outputs
        type: "json_schema",
        json_schema: {
            name: "email_schema",
            schema: {
                type: "object",
                properties: {
                    email: {
                        description: "The email address that appears in the input",
                        type: "string"
                    }
                },
                additionalProperties: false
            }
        }
    }
});

console.log(completion.choices[0].message.content);
```

```python
from openai import OpenAI
client = OpenAI()

response = client.chat.completions.create(
    model="gpt-4o-2024-08-06",
    messages=[
        {
            "role": "developer", 
            "content": "You extract email addresses into JSON data."
        },
        {
            "role": "user", 
            "content": "Feeling stuck? Send a message to help@mycompany.com."
        }
    ],
    response_format={
        "type": "json_schema",
        "json_schema": {
            "name": "email_schema",
            "schema": {
                "type": "object",
                "properties": {
                    "email": {
                        "description": "The email address that appears in the input",
                        "type": "string"
                    },
                    "additionalProperties": False
                }
            }
        }
    }
)

print(response.choices[0].message.content);
```

```bash
curl https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{
    "model": "gpt-4o-2024-08-06",
    "messages": [
      {
        "role": "developer",
        "content": "You extract email addresses into JSON data."
      },
      {
        "role": "user",
        "content": "Feeling stuck? Send a message to help@mycompany.com."
      }
    ],
    "response_format": {
      "type": "json_schema",
      "json_schema": {
        "name": "email_schema",
        "schema": {
            "type": "object",
            "properties": {
                "email": {
                    "description": "The email address that appears in the input",
                    "type": "string"
                }
            },
            "additionalProperties": false
        }
      }
    }
  }'
```

Choosing a model
----------------

When making a text generation request, the first option to configure is which [model](/docs/models) you want to generate the response. The model you choose can greatly influence the output, and impact how much each generation request [costs](https://openai.com/api/pricing/).

*   A **large model** like [`gpt-4o`](/docs/models#gpt-4o) will offer a very high level of intelligence and strong performance, while having a higher cost per token.
*   A **small model** like [`gpt-4o-mini`](/docs/models#gpt-4o-mini) offers intelligence not quite on the level of the larger model, but is faster and less expensive per token.
*   A **reasoning model** like [the `o1` family of models](/docs/models#o1) is slower to return a result, and uses more tokens to "think", but is capable of advanced reasoning, coding, and multi-step planning.

Experiment with different models [in the Playground](/playground) to see which one works best for your prompts! More information on choosing a model can [also be found here](/docs/guides/model-selection).

Building prompts
----------------

The process of crafting prompts to get the right output from a model is called **prompt engineering**. By giving the model precise instructions, examples, and necessary context information (like private or specialized information that wasn't included in the model's training data), you can improve the quality and accuracy of the model's output. Here, we'll get into some high-level guidance on building prompts, but you might also find the [prompt engineering guide](/docs/guides/prompt-engineering) helpful.

In the [chat completions](/docs/api-reference/chat/) API, you create prompts by providing an array of `messages` that contain instructions for the model. Each message can have a different `role`, which influences how the model might interpret the input.

### User messages

User messages contain instructions that request a particular type of output from the model. You can think of `user` messages as the messages you might type in to [ChatGPT](https://chaptgpt.com) as an end user.

Here's an example of a user message prompt that asks the `gpt-4o` model to generate a haiku poem based on a prompt.

```javascript
const response = await openai.chat.completions.create({
  model: "gpt-4o",
  messages: [
    {
      "role": "user",
      "content": [
        {
          "type": "text",
          "text": "Write a haiku about programming."
        }
      ]
    }
  ]
});
```

### Developer messages

Messages with the `developer` role provide instructions to the model that are prioritized ahead of user messages, as described in the [chain of command section in the model spec](https://cdn.openai.com/spec/model-spec-2024-05-08.html#follow-the-chain-of-command). They typically describe how the model should generally behave and respond. This message role used to be called the `system` prompt, but it has been renamed to more accurately describe its place in the instruction-following hierarchy.

Here's an example of a developer message that modifies the behavior of the model when generating a response to a `user` message:

```javascript
const response = await openai.chat.completions.create({
  model: "gpt-4o",
  messages: [
    {
      "role": "developer",
      "content": [
        {
          "type": "text",
          "text": `
            You are a helpful assistant that answers programming 
            questions in the style of a southern belle from the 
            southeast United States.
          `
        }
      ]
    },
    {
      "role": "user",
      "content": [
        {
          "type": "text",
          "text": "Are semicolons optional in JavaScript?"
        }
      ]
    }
  ]
});
```

This prompt returns a text output in the rhetorical style requested:

```text
Well, sugar, that's a fine question you've got there! Now, in the 
world of JavaScript, semicolons are indeed a bit like the pearls 
on a necklace – you might slip by without 'em, but you sure do look 
more polished with 'em in place. 

Technically, JavaScript has this little thing called "automatic 
semicolon insertion" where it kindly adds semicolons for you 
where it thinks they oughta go. However, it's not always perfect, 
bless its heart. Sometimes, it might get a tad confused and cause 
all sorts of unexpected behavior.
```

### Assistant messages

Messages with the `assistant` role are presumed to have been generated by the model, perhaps in a previous generation request (see the "Conversations" section below). They can also be used to provide examples to the model for how it should respond to the current request - a technique known as **few-shot learning**.

Here's an example of using an assistant message to capture the results of a previous text generation result, and making a new request based on that.

```javascript
const response = await openai.chat.completions.create({
  model: "gpt-4o",
  messages: [
    {
      "role": "user",
      "content": [{ "type": "text", "text": "knock knock." }]
    },
    {
      "role": "assistant",
      "content": [{ "type": "text", "text": "Who's there?" }]
    },
    {
      "role": "user",
      "content": [{ "type": "text", "text": "Orange." }]
    }
  ]
});
```

### Giving the model additional data to use for generation

The message types above can also be used to provide additional information to the model which may be outside its training data. You might want to include the results of a database query, a text document, or other resources to help the model generate a relevant response. This technique is often referred to as **retrieval augmented generation**, or RAG. [Learn more about RAG techniques here](https://help.openai.com/en/articles/8868588-retrieval-augmented-generation-rag-and-semantic-search-for-gpts).

Conversations and context
-------------------------

While each text generation request is independent and stateless (unless you are using [assistants](/docs/assistants/overview)), you can still implement **multi-turn conversations** by providing additional messages as parameters to your text generation request. Consider the "knock knock" joke example shown above:

```javascript
const response = await openai.chat.completions.create({
  model: "gpt-4o",
  messages: [
    {
      "role": "user",
      "content": [{ "type": "text", "text": "knock knock." }]
    },
    {
      "role": "assistant",
      "content": [{ "type": "text", "text": "Who's there?" }]
    },
    {
      "role": "user",
      "content": [{ "type": "text", "text": "Orange." }]
    }
  ]
});
```

By using alternating `user` and `assistant` messages, you can capture the previous state of a conversation in one request to the model.

### Managing context for text generation

As your inputs become more complex, or you include more and more turns in a conversation, you will need to consider both **output token** and **context window** limits. Model inputs and outputs are metered in [**tokens**](https://help.openai.com/en/articles/4936856-what-are-tokens-and-how-to-count-them), which are parsed from inputs to analyze their content and intent, and assembled to render logical outputs. Models have limits on how many tokens can be used during the lifecycle of a text generation request.

*   **Output tokens** are the tokens that are generated by a model in response to a prompt. Each model supports different limits for output tokens, [documented here](/docs/models). For example, `gpt-4o-2024-08-06` can generate a maximum of 16,384 output tokens.
*   A **context window** describes the total tokens that can be used for both input tokens and output tokens (and for some models, [reasoning tokens](/docs/guides/reasoning)), [documented here](/docs/models). For example, `gpt-4o-2024-08-06` has a total context window of 128k tokens.

If you create a very large prompt (usually by including a lot of conversation context or additional data/examples for the model), you run the risk of exceeding the allocated context window for a model, which might result in truncated outputs.

You can use the [tokenizer tool](/tokenizer) (which uses the [tiktoken library](https://github.com/openai/tiktoken)) to see how many tokens are present in a string of text.

Optimizing model outputs
------------------------

As you iterate on your prompts, you will be continually trying to improve **accuracy**, **cost**, and **latency**.

||
|Accuracy|Ensure the model produces accurate and useful responses to your prompts.|Accurate responses require that the model has all the information it needs to generate a response, and knows how to go about creating a response (from interpreting input to formatting and styling). Often, this will require a mix of prompt engineering, RAG, and model fine-tuning.Learn about optimizing for accuracy here.|
|Cost|Drive down the total cost of model usage by reducing token usage and using cheaper models when possible.|To control costs, you can try to use fewer tokens or smaller, cheaper models. Learn more about optimizing for cost here.|
|Latency|Decrease the time it takes to generate responses to your prompts.|Optimizing latency is a multi-faceted process including prompt engineering, parallelism in your own code, and more. Learn more here.|

Next steps
----------

There's much more to explore in text generation - here's a few resources to go even deeper.

[

Prompt examples

Get inspired by example prompts for a variety of use cases.

](/docs/examples)[

Build a prompt in the Playground

Use the Playground to develop and iterate on prompts.

](/playground)[

Browse the Cookbook

The Cookbook has complex examples covering a variety of use cases.

](/docs/guides/https://cookbook.openai.com)[

Generate JSON data with Structured Outputs

Ensure JSON data emitted from a model conforms to a JSON schema.

](/docs/guides/structured-outputs)[

Full API reference

Check out all the options for text generation in the API reference.

](/docs/api-reference/chat)

Was this page useful?
