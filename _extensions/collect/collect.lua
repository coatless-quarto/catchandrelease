-- Initialize a global table to store the CodeDiv elements
_G.codeDivs = {}

-- Retrieve all CodeBlocks and store them individually. 
local function captureCode(elem)

    -- Check if the CodeBlock contains any options
    local options = {}
    local code = elem.text
    for line in elem.text:gmatch('[^\n]+') do
        local key, value = line:match('#|%s*(%w+)%s*:%s*(%S+)')
        if key and value then
            options[key] = value
        end
    end

    -- Increment the order
    _G.order = (_G.order or 0) + 1

    -- Create a custom Div element to store the code and options
    local codeDiv = pandoc.Div({
      code
    })

    -- codeDiv.attr({cellid = _G.order, options = options})
  
    -- Store the CodeDiv in the global table
    table.insert(_G.codeDivs, codeDiv)

    -- Return to keep the original CodeBlock in the document
    return elem
end

-- Define a function to combine CodeDivs into a string
local function combineCodeDivs()

  local combinedCode = ""

  -- Combine the elements inside the Div
  for _, codeDiv in pairs(_G.codeDivs) do
    combinedCode = combinedCode .. pandoc.utils.stringify(codeDiv) .. ","
  end

  -- Remove the trailing comma
  combinedCode = combinedCode:sub(1, -2)

  return combinedCode
end

-- Define a function to write the global table to a JSON file
function writeCodeDivsToJson()
  -- Setup a table for JSON
  local jsonTable = {}

  -- Iterate through items
  for _, codeDiv in pairs(_G.codeDivs) do
      table.insert(jsonTable, {
          code = pandoc.utils.stringify(codeDiv)
      })
  end

  -- Serialize the table to JSON
  local jsonStr = quarto.json.encode(jsonTable)

  return jsonStr
end

-- Call the function to combine CodeDivs and write the output to the end of the document
local function injectCode(doc)

  -- Write the content out as a string
  -- local combinedCode = combineCodeDivs()

  -- Write JSON code out
  local jsonCode = writeCodeDivsToJson()

  -- Create a new paragraph with the combined code 
  local para = pandoc.Para(jsonCode)

  -- add it to the end of the document
  table.insert(doc.blocks, para)

  return doc
end

-- Typewise traversal order: https://pandoc.org/lua-filters.html#typewise-traversal
-- 1. functions for Inline elements,
-- 2. the Inlines filter function,
-- 3. functions for Block elements ,
-- 4. the Blocks filter function,
-- 5. the Meta filter function, and last
-- 6. the Pandoc filter function.
-- Order can be changed by modifying the return order. 

return {
  { CodeBlock = captureCode },     -- (1)
  { Pandoc = injectCode }          -- (2)
}

