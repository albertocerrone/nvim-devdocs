M = {}

local normalize_html = function(str)
  str = str:gsub("&copy;", "©")
  str = str:gsub("&ndash;", "–")
  str = str:gsub("&lt;", "<")
  str = str:gsub("&gt;", ">")
  str = str:gsub("&amp;", "&")

  return str
end

local tag_mappings = {
  h1 = { left = "# ", right = "\n\n" },
  h2 = { left = "## ", right = "\n\n" },
  h3 = { left = "### ", right = "\n\n" },
  h4 = { left = "#### ", right = "\n\n" },
  h5 = { left = "##### ", right = "\n\n" },
  h6 = { left = "###### ", right = "\n\n" },
  div = { right = "\n" },
  section = { right = "\n" },
  p = { right = "\n\n" },
  ul = { right = "\n" },
  ol = { right = "\n" },
  dl = { right = "\n" },
  dt = { right = "\n" },
  figure = { right = "\n" },
  dd = { left = ": " },
  span = {},
  header = {},
  thead = {},
  tbody = {},
  pre = { left = "```\n", right = "```" },
  code = { left = "`", right = "`" },
  samp = { left = "`", right = "`" },
  var = { left = "`", right = "`" },
  kbd = { left = "`", right = "`" },
  strong = { left = "**", right = "**" },
  em = { left = " _", right = "_ " },
  small = { left = " _", right = "_ " },
  sup = { left = "^", right = "^" },
  blockquote = { left = "> " },

  br = { right = "\n" },
  hr = { right = "---" },
}

M.to_yaml = function(entry)
  local lines = {}

  for key, value in pairs(entry) do
    if key == "attribution" then
      value = normalize_html(value)
      value = value:gsub("<a.*>(.*)</a>", "%1")
      value = value:gsub("<br>", "")
      value = value:gsub("\n *", " ")
    end
    if key == "links" then value = vim.fn.json_encode(value) end
    table.insert(lines, key .. ": " .. value)
  end

  return table.concat(lines, "\n")
end

M.html_to_md = function(html)
  local transpiler = {
    parser = vim.treesitter.get_string_parser(html, "html"),
    lines = vim.split(html, "\n"),
    result = "",
  }

  ---@param node TSNode
  function transpiler:get_node_text(node)
    local row_start, col_start = node:start()
    local row_end, col_end = node:end_()
    local extracted_lines = {}

    for i = row_start, row_end do
      local line = self.lines[i + 1]

      if row_start == row_end then
        line = line:sub(col_start + 1, col_end)
      elseif i == row_start then
        line = line:sub(col_start + 1)
      elseif i == row_end then
        line = line:sub(1, col_end)
      end

      table.insert(extracted_lines, line)
    end

    return table.concat(extracted_lines, "\n")
  end

  function transpiler:transpile()
    self.parser:parse()
    self.parser:for_each_tree(function(tree)
      local root = tree:root()

      if root then
        local children = root:named_children()

        for _, node in pairs(children) do
          self.result = self.result .. self:eval(node)
        end
      end
    end)

    return self.result
  end

  ---@param node TSNode
  function transpiler:eval(node)
    local result = ""
    local node_type = node:type()
    local node_text = self:get_node_text(node)

    if node_type == "text" or node_type == "entity" then
      result = result .. normalize_html(node_text)
    elseif node_type == "element" then
      local children = node:named_children()
      local tag_node = children[1]
      local tag_children = tag_node:named_children()
      local tag_type = tag_node:type()
      local tag_name = self:get_node_text(tag_node:named_child())
      local attributes = {}

      for i = 2, #tag_children do
        local attribute_node = tag_children[i]
        local attribute_name_node = attribute_node:named_child()
        local attribute_name = self:get_node_text(attribute_name_node)
        local value = ""

        if attribute_name_node:next_named_sibling() then
          local quotetd_value_node = attribute_name_node:next_named_sibling()
          local value_node = quotetd_value_node:named_child()
          if value_node then value = self:get_node_text(value_node) end
        end

        attributes[attribute_name] = value
      end

      if tag_type == "start_tag" then
        for i = 2, #children - 1 do
          result = result .. self:eval(children[i])
        end
      end

      local skipable = { "tr", "td", "th" }
      if vim.tbl_contains(skipable, tag_name) then return "" end

      if tag_name == "a" then
        result = string.format("[%s](%s)", result, attributes.href)
      elseif tag_name == "img" then
        result = string.format("![%s](%s)", attributes.alt, attributes.src)
      elseif tag_name == "pre" and attributes["data-language"] then
        result = "```" .. attributes["data-language"] .. "\n" .. result .. "\n```\n"
      elseif tag_name == "table" then
        result = self:eval_table(node)
      elseif tag_name == "abbr" then
        result = string.format("%s(%s)", result, attributes.title)
      elseif tag_name == "iframe" then
        result = string.format("[%s](%s)", attributes.title, attributes.src)
      elseif tag_name == "li" then
        local parent_node = node:parent()
        local parent_tag_name_node = parent_node:named_child():named_child()
        local parent_tag_name = self:get_node_text(parent_tag_name_node)

        if parent_tag_name == "ul" then result = "- " .. result .. "\n" end
        if parent_tag_name == "ol" then
          local siblings = parent_node:named_children()
          for i = 2, #siblings - 1 do
            if node:equal(siblings[i]) then result = i - 1 .. ". " .. result .. "\n" end
          end
        end
      else
        local map = tag_mappings[tag_name]
        if map then
          local left = map.left and map.left or ""
          local right = map.right and map.right or ""
          result = left .. result .. right
        else
          result = result .. node_text
        end
      end
    end

    result = result:gsub("\n\n\n+", "\n\n")

    return result
  end

  ---@param node TSNode
  function transpiler:eval_table(node)
    local children = node:named_children()
    local result = ""
    local max_col_len = {}

    for i = 2, #children - 1 do
      local child_node = children[i]
      local child_tag_node = child_node:named_child():named_child()
      local child_tag_name = self:get_node_text(child_tag_node)

      if child_tag_name == "thead" or child_tag_name == "tbody" then
        result = result .. self:eval_table(child_node)
      end

      if child_tag_name == "tr" then
        local col_nodes = child_node:named_children()
        -- TODO
      end
    end

    return result
  end

  return transpiler:transpile()
end

-- local md = M.html_to_md([[
-- <table>
--   <thead>
--     <tr>
--       <th>Header 1</th>
--       <th>Header 2</th>
--     </tr>
--   </thead>
--   <tbody>
--     <tr>
--       <td>Row 1, Cell 1</td>
--       <td>Row 1, Cell 2</td>
--     </tr>
--     <tr>
--       <td>Row 2, Cell 1</td>
--       <td>Row 2, Cell 2</td>
--     </tr>
--   </tbody>
-- </table>
-- ]])
--
-- print(md)
--
-- | Header 1     | Header 2     |
-- | ------------ | ------------ |
-- | Row 1, Cell 1| Row 1, Cell 2|
-- | Row 2, Cell 1| Row 2, Cell 2|

return M
