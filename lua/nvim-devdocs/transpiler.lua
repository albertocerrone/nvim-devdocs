M = {}

local normalize_html = function(str)
  str = str:gsub("&lt;", "<")
  str = str:gsub("&gt;", ">")
  str = str:gsub("&amp;", "&")
  str = str:gsub("&quot;", '"')
  str = str:gsub("&apos;", "'")
  str = str:gsub("&nbsp;", " ")
  str = str:gsub("&copy;", "©")
  str = str:gsub("&ndash;", "–")

  return str
end

local tag_mappings = {
  h1 = { left = "# ", right = "\n\n" },
  h2 = { left = "## ", right = "\n\n" },
  h3 = { left = "### ", right = "\n\n" },
  h4 = { left = "#### ", right = "\n\n" },
  h5 = { left = "##### ", right = "\n\n" },
  h6 = { left = "###### ", right = "\n\n" },
  span = {},
  header = {},
  div = { right = "\n" },
  section = { right = "\n" },
  p = { right = "\n\n" },
  ul = { right = "\n" },
  ol = { right = "\n" },
  dl = { right = "\n" },
  dt = { right = "\n" },
  figure = { right = "\n" },
  dd = { left = ": " },
  pre = { left = "```\n", right = "```\n" },
  code = { left = "`", right = "`" },
  samp = { left = "`", right = "`" },
  var = { left = "`", right = "`" },
  kbd = { left = "`", right = "`" },
  b = { left = "`", right = "`" },
  strong = { left = "**", right = "**" },
  em = { left = " _", right = "_ " },
  small = { left = " _", right = "_ " },
  sup = { left = "^", right = "^" },
  blockquote = { left = "> " },
  summary = { left = "<", right = ">" },
  math = { left = "```math\n", right = "\n```" },
  annotation = { left = "[", right = "]" },
  semantics = {},
  mspace = { left = " " },
  msup = { right = "^" },
  mfrac = { right = "/" },
  mrow = {},
  mo = {},
  mn = {},
  mi = {},

  br = { right = "\n" },
  hr = { right = "---" },
}

-- exceptions, table -> child
local skipable_tag = {
  "tr",
  "td",
  "th",
  "thead",
  "tbody",
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

  ---@param node TSNode
  ---@return string
  function transpiler:get_node_tag_name(node)
    local tag_node = node:named_child():named_child()
    local tag_name = self:get_node_text(tag_node)

    return tag_name
  end

  ---@param node TSNode
  function transpiler:get_node_attributes(node)
    local attributes = {}
    local tag_node = node:named_child()

    if tag_node == nil then return {} end

    local tag_children = tag_node:named_children()

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

    return attributes
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
      local tag_type = tag_node:type()
      local tag_name = self:get_node_text(tag_node:named_child())
      local attributes = self:get_node_attributes(node)

      if tag_type == "start_tag" then
        for i = 2, #children - 1 do
          result = result .. self:eval(children[i])
        end
      end

      if vim.tbl_contains(skipable_tag, tag_name) then return "" end

      if tag_name == "a" then
        result = string.format("[%s](%s)", result, attributes.href)
      elseif tag_name == "img" then
        result = string.format("![%s](%s)", attributes.alt, attributes.src)
      elseif tag_name == "pre" and attributes["data-language"] then
        result = "```" .. attributes["data-language"] .. "\n" .. result .. "\n```\n"
      elseif tag_name == "abbr" then
        result = string.format("%s(%s)", result, attributes.title)
      elseif tag_name == "iframe" then
        result = string.format("[%s](%s)\n", attributes.title, attributes.src)
      elseif tag_name == "table" then
        result = self:eval_table(node)
      elseif tag_name == "li" then
        local parent_node = node:parent()
        local parent_tag_name = self:get_node_tag_name(parent_node)

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
    local result = ""
    local children = node:named_children()
    ---@type TSNode[]
    local tr_nodes = {}

    -- assumes existing thead, tbody
    for i = 2, #children - 1 do
      local t_children = children[i]:named_children()
      local t_tr = vim.tbl_filter(
        function(child_node)
          return child_node:type() ~= "start_tag" and child_node:type() ~= "end_tag"
        end,
        t_children
      )

      vim.list_extend(tr_nodes, t_tr)
    end

    local max_col_len = {}
    local result_map = {}
    local colspan_map = {}

    for i, tr in ipairs(tr_nodes) do
      local tr_children = tr:named_children()
      result_map[i] = {}
      colspan_map[i] = {}

      for j = 2, #tr_children - 1 do
        local inner_result = ""
        local tcol_node = tr_children[j]
        local tcol_children = tcol_node:named_children()
        local attributes = self:get_node_attributes(tcol_node)

        for k = 2, #tcol_children - 1 do
          inner_result = self:eval(tcol_children[k])
        end

        result_map[i][j - 1] = inner_result
        colspan_map[i][j - 1] = attributes.colspan and attributes.colspan or 1

        if max_col_len[j - 1] == nil then max_col_len[j - 1] = 0 end
        if max_col_len[j - 1] < #inner_result then max_col_len[j - 1] = #inner_result end
      end
    end

    for i = 1, #tr_nodes do
      for j, value in ipairs(result_map[i]) do
        local col_len = max_col_len[j]
        local colspan = tonumber(colspan_map[i][j])
        result = result .. "| " .. value .. string.rep(" ", col_len - #value + 1)

        for k = 2, colspan do
          local spacing = max_col_len[j + k]
          if spacing then result = result .. string.rep(" ", spacing + 3) end
        end
      end

      result = result .. "|\n"

      if i == 1 then
        for j = 1, #result_map[i] do
          local col_len = max_col_len[j]
          local colspan = tonumber(colspan_map[i][j])
          local line = string.rep("-", col_len)

          for k = 2, colspan do
            local spacing = max_col_len[j + k]
            if spacing then line = line .. string.rep("-", spacing + 3) end
          end
          result = result .. "| " .. line .. " "
        end

        result = result .. "|\n"
      end
    end

    return result
  end

  function transpiler:transpile()
    self.parser:parse()
    self.parser:for_each_tree(function(tree)
      local root = tree:root()
      if root then
        local children = root:named_children()
        for _, node in ipairs(children) do
          self.result = self.result .. self:eval(node)
        end
      end
    end)

    return self.result
  end

  return transpiler:transpile()
end

return M
