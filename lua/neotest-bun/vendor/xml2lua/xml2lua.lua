local xml2lua = { _VERSION = "1.6-1" }
local XmlParser = require("neotest-bun.vendor.xml2lua.XmlParser")

local function printableInternal(tb, level)
  if tb == nil then
     return
  end

  level = level or 1
  local spaces = string.rep(' ', level*2)
  for k,v in pairs(tb) do
      if type(v) == "table" then
         print(spaces .. k)
         printableInternal(v, level+1)
      else
         print(spaces .. k..'='..v)
      end
  end
end

function xml2lua.parser(handler)
    if handler == xml2lua then
        error("You must call xml2lua.parse(handler) instead of xml2lua:parse(handler)")
    end

    local options = {
            --Indicates if whitespaces should be striped or not
            stripWS = 1,
            expandEntities = 1,
            errorHandler = function(errMsg, pos)
                error(string.format("%s [char=%d]\n", errMsg or "Parse Error", pos))
            end
          }

    return XmlParser.new(handler, options)
end

function xml2lua.printable(tb)
    printableInternal(tb)
end

function xml2lua.toString(t)
    local sep = ''
    local res = ''
    if type(t) ~= 'table' then
        return t
    end

    for k,v in pairs(t) do
        if type(v) == 'table' then
            v = xml2lua.toString(v)
        end
        res = res .. sep .. string.format("%s=%s", k, v)
        sep = ','
    end
    res = '{'..res..'}'

    return res
end

function xml2lua.loadFile(xmlFilePath)
    local f, e = io.open(xmlFilePath, "r")
    if f then
        --Gets the entire file content and stores into a string
        local content = f:read("*a")
        f:close()
        return content
    end

    error(e)
end

local function attrToXml(attrTable)
  local s = ""
  attrTable = attrTable or {}

  for k, v in pairs(attrTable) do
      s = s .. " " .. k .. "=" .. '"' .. v .. '"'
  end
  return s
end

local function getSingleChild(tb)
  local count = 0
  for _ in pairs(tb) do
    count = count + 1
  end
  if (count == 1) then
      for k, _ in pairs(tb) do
          return k
      end
  end
  return nil
end

local function getFirstValue(tb)
  if type(tb) == "table" then
    for _, v in pairs(tb) do
      return v
    end
      return nil
   end

   return tb
end

xml2lua.pretty = true

function xml2lua.getSpaces(level)
  local spaces = ''
  if (xml2lua.pretty) then
    spaces = string.rep(' ', level * 2)
  end
  return spaces
end

function xml2lua.addTagValueAttr(tagName, tagValue, attrTable, level)
  local attrStr = attrToXml(attrTable)
  local spaces = xml2lua.getSpaces(level)
  if (tagValue == '') then
    table.insert(xml2lua.xmltb, spaces .. '<' .. tagName .. attrStr .. '/>')
  else
    table.insert(xml2lua.xmltb, spaces .. '<' .. tagName .. attrStr .. '>' .. tostring(tagValue) .. '</' .. tagName .. '>')
  end
end

function xml2lua.startTag(tagName, attrTable, level)
  local attrStr = attrToXml(attrTable)
  local spaces = xml2lua.getSpaces(level)
  if (tagName ~= nil) then
    table.insert(xml2lua.xmltb, spaces .. '<' .. tagName .. attrStr .. '>')
  end
end

function xml2lua.endTag(tagName, level)
  local spaces = xml2lua.getSpaces(level)
  if (tagName ~= nil) then
    table.insert(xml2lua.xmltb, spaces .. '</' .. tagName .. '>')
  end
end

function xml2lua.isChildArray(obj)
  for tag, _ in pairs(obj) do
    if (type(tag) == 'number') then
      return true
    end
  end
  return false
end

function xml2lua.isTableEmpty(obj)
  for k, _ in pairs(obj) do
    if (k ~= '_attr') then
      return false
    end
  end
  return true
end

function xml2lua.parseTableToXml(obj, tagName, level)
  if (tagName ~= '_attr') then
    if (type(obj) == 'table') then
      if (xml2lua.isChildArray(obj)) then
        for _, value in pairs(obj) do
          xml2lua.parseTableToXml(value, tagName, level)
        end
      elseif xml2lua.isTableEmpty(obj) then
        xml2lua.addTagValueAttr(tagName, "", obj._attr, level)
      else
        xml2lua.startTag(tagName, obj._attr, level)
        for tag, value in pairs(obj) do
          xml2lua.parseTableToXml(value, tag, level + 1)
        end
        xml2lua.endTag(tagName, level)
      end
    else
      xml2lua.addTagValueAttr(tagName, obj, nil, level)
    end
  end
    end

function xml2lua.toXml(tb, tableName, level)
  xml2lua.xmltb = {}
  level = level or 0
  local singleChild = getSingleChild(tb)
  tableName = tableName or singleChild

  if (singleChild) then
    xml2lua.parseTableToXml(getFirstValue(tb), tableName, level)
            else
    xml2lua.parseTableToXml(tb, tableName, level)
  end

  if (xml2lua.pretty) then
    return table.concat(xml2lua.xmltb, '\n')
  end
  return table.concat(xml2lua.xmltb)
end

return xml2lua
