-- A simple YAML parser
local function parse_yaml(yaml)
  local metadata = {}
  for line in yaml:gmatch("[^\r\n]+") do
    local key, value = line:match("^%s*(%S+)%s*:%s*(.+)")
    if key then
      -- Remove quotes if they exist
      value = value:gsub("^['\"]?(.+?)['\"]?$", "%1")
      metadata[key] = value
    end
  end
  return metadata
end

-- List of small words that should not be capitalized in title case
local small_words = {
  ["and"] = true,
  ["or"] = true,
  ["in"] = true,
  ["on"] = true,
  ["of"] = true,
  ["at"] = true,
  ["to"] = true,
  ["da"] = true,
  ["for"] = true,
  ["vs"] = true,
  ["with"] = true,
  ["the"] = true,
  ["a"] = true,
  ["ain't"] = true,
  ["is"] = true,
  ["n"] = true,
  ["an"] = true
}

-- Function to format a string to title case
local function title_case(title)
  local words = {}
  local first = true
  for word in title:gmatch("%S+") do
    -- Capitalize if it's the first word or not a small word
    if first or not small_words[word:lower()] then
      table.insert(words, word:sub(1, 1):upper() .. word:sub(2):lower())
    else
      table.insert(words, word:lower())
    end
    first = false
  end
  return table.concat(words, " ")
end

-- Function to extract YAML metadata from a linked file
local function get_title_from_linked_md(filepath)
  local file = io.open(filepath, "r")
  if not file then
--    print("Error: Unable to open file " .. filepath)  -- Debugging
    return nil  -- Return nil if the file cannot be opened
  end

  local content = file:read("*all")
  file:close()

--  print("Reading file: " .. filepath)  -- Debugging
--  print(content)  -- Debugging: Print the content of the file

  -- Extract YAML front matter using a simple pattern
  local yaml = content:match("^%-%-%-(.-)%-%-%-")
  if yaml then
--    print("YAML front matter found: " .. yaml)  -- Debugging
    local metadata = parse_yaml(yaml)

    -- Checking if 'metadata' contains a title
    if metadata.title then
      local title = metadata.title
--      print("Extracted title: " .. title)  -- Debugging
      return title
    else
--      print("Error: Title not found in metadata.")  -- Debugging
    end
  else
--    print("Error: YAML front matter not found.")  -- Debugging
  end
  return nil
end

-- Process Links to format based on the metadata of the linked .md file
function Link(el)
  -- Check if the link target ends with ".md"
  if string.match(el.target, "%.md$") then
    -- Replace the target extension from .md to .html
    local target_html = string.gsub(el.target, "%.md$", ".html")

    -- Extract the base filename without the extension
    local name = string.match(el.target, "([^/]+)%.md$")

    -- Separate the date (YYYY-MM-DD) and the slug-title from the filename
    local date, slug_title = string.match(name, "^(%d+%-%d+%-%d+)%-(.+)$")

    if date and slug_title then
      -- Attempt to get the title from the linked .md file's YAML metadata
      local linked_file_title = get_title_from_linked_md(el.target)

      -- If the linked file has a title, use it; otherwise, use slug-derived title
      local formatted_title = linked_file_title and title_case(linked_file_title) or title_case(slug_title:gsub("%-", " "))

      -- Create the new formatted string for the link
      local html_link = date .. ': <a href="' .. target_html .. '">' .. formatted_title .. '</a>'

      -- Return a raw HTML block to inject the link as HTML directly
      return pandoc.RawInline("html", html_link)
    end
  end
  return el
end

return {
  {
    Link = Link
  }
}