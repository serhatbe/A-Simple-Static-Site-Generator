-- dropcap.lua
-- Applies a drop cap to the first long paragraph in the document

local dropcap_applied = false  -- Ensure it's only applied once
local word_threshold = 25      -- Minimum word count to qualify as a "long" paragraph

-- Helper: Count total words in a paragraph
local function count_words(para)
  local count = 0
  for _, el in ipairs(para.content) do
    if el.t == "Str" then
      for _ in el.text:gmatch("%S+") do
        count = count + 1
      end
    end
  end
  return count
end

-- Helper: Find the index of the first Str element
local function find_first_str_index(content)
  for i, el in ipairs(content) do
    if el.t == "Str" then
      return i
    end
  end
  return nil
end

-- Main filter function for Paragraphs
function apply_dropcap(para)
  if dropcap_applied or para.t ~= "Para" then
    return para
  end

  if count_words(para) >= word_threshold then
    local i = find_first_str_index(para.content)
    if i then
      local first_word = para.content[i]
      local first_letter = first_word.text:sub(1, 1)
      local rest = first_word.text:sub(2)

      -- Build the dropcap span
      local dropcap = pandoc.RawInline("html", '<span class="dropcap">' .. first_letter .. '</span>')

      -- Replace the first word and insert the span
      para.content[i] = pandoc.Str(rest)
      table.insert(para.content, i, dropcap)

      dropcap_applied = true
    end
  end

  return para
end

return {
  { Para = apply_dropcap }
}