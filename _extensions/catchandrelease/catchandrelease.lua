-- Initialize a table to store the CodeDiv elements
local capturedCodeBlocks = {}

-- Store the number of CodeBlocks visited
local counterCodeBlock = 0

-- Retrieve all CodeBlocks and store them individually. 
local function captureCode(elem)

  -- Extract the code
  local code = elem.text

  -- Check if the CodeBlock contains any options
  local codeBlockOptions = {}
  
  for line in elem.text:gmatch('[^\n]+') do
      local key, value = line:match('#|%s*(%w+)%s*:%s*(%S+)')
      if key and value then
        codeBlockOptions[key] = value
      end
  end

  -- Merge the attributes into the codeBlockData table
  for key, value in pairs(elem.attributes) do
    codeBlockOptions[key] = value
  end

  -- Increment the order
  counterCodeBlock = counterCodeBlock + 1

  -- Create a new table for the CodeBlock
  local codeBlockData = {
    id = counterCodeBlock,
    code = code,
    attrs = codeBlockOptions
  }

  -- Store the CodeDiv in the global table
  table.insert(capturedCodeBlocks, codeBlockData)

  -- Return to keep the original CodeBlock in the document
  return elem
end

-- Define a function to combine CodeDivs into a string
local function combineCodeBlocksAsString()

  local combinedCode = ""

  -- Combine the elements inside the Div
  for _, codeCell in ipairs(capturedCodeBlocks) do
    local codeValue = codeCell.code
    combinedCode = combinedCode .. pandoc.utils.stringify(codeValue) .. ","
  end

  -- Remove the trailing comma
  combinedCode = combinedCode:sub(1, -2)

  return combinedCode
end

-- Define a function to write the CodeBlocks table to a JSON file
function writeCodeBlocksToJson()
  -- Setup a table for JSON
  local jsonTable = {}

  -- Iterate through items
  for _, codeCell in ipairs(capturedCodeBlocks) do
    local codeValue = codeCell.code
    table.insert(jsonTable, {
        code = pandoc.utils.stringify(codeValue)
    })
  end

  -- Serialize the table to JSON
  local jsonStr = quarto.json.encode(jsonTable)

  return jsonStr
end

-- Call the function to combine CodeBlocks and write the output to the end of the document
local function releaseCode(doc)

  -- Write the content out as a string
  -- local combinedCode = combineCodeBlocksAsString()

  -- Write JSON code out
  local jsonCode = writeCodeBlocksToJson()

  -- Create a new paragraph with the combined code 
  local para = pandoc.Para(jsonCode)

  -- add it to the end of the document
  table.insert(doc.blocks, para)

  return doc
end

-- Specify traversal order
return {
  { CodeBlock = captureCode },     -- (1)
  { Pandoc = releaseCode }          -- (2)
}

