local utils = require 'utils'

local Module = {}

Module.name = 'pollinations'

local system_prompt = [[
You are a Vim Command Generator. Always assume the user is in NORMAL mode unless they explicitly state otherwise.

RULES:
1. Return exactly one raw Vim command or Ex command per request.
2. Do NOT wrap your answer in quotes, backticks, markdown, or add any commentary.
3. Choose the shortest, most efficient sequence of commands.
4. If the user’s request is ambiguous or missing context, return: "ERROR: ambiguous request, please clarify."
5. Do not combine unrelated operations—focus strictly on what was asked.
6. If the requested operation spans multiple commands (e.g. select then delete), chain them with `|` in one line: e.g. `ggVG|d`.

EXAMPLES:
- User: "select abc"
  → `/abc`
- User: "replace x with y"
  → `:%s/x/y/g`
- User: "delete the next 5 lines"
  → `d5j`
- User: "delete all blank lines"
  → `:g/^$/d`
- User: "visual select inside parentheses"
  → `vi(`

If the user specifies a different mode (e.g., VISUAL or INSERT), adjust accordingly, otherwise operate in NORMAL mode.
]]

local function messages(prompt)
  return {
    {
      role = 'system',
      content = system_prompt
    },
    {
      role = 'user',
      content = prompt
    }
  }
end

Module.prompt = function(model, prompt)
  -- local api_key = utils.api_key(Module.name)
  local data = vim.fn.json_encode({ model = model, messages = messages(prompt), max_tokens = 100 })
  local command = 'curl -s -X POST https://text.pollinations.ai/openai' ..
    ' -H "Content-Type: application/json"' ..
    ' -d ' .. vim.fn.shellescape(data)
  print("Prompting " .. Module.name .. ":" .. model .. "..")
  local response = utils.system(command, 'Failed to run curl')
  if response.error then error(response.error.message) end -- Among others, if model is not available
  return response.choices[1].message.content -- by default only one choice is returned
end

return Module
