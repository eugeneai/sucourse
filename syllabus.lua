-- json = require("json")
-- tbl = require("table.save-0.94.lua")
mq = require("rabbitmqstomp.lua")

ALL = {}

-- print("\n\n-------->", _VERSION, "\n\n")

function soe(v) -- string or empty
   if v == 'nil' then v = nil end
   if v~=nil and (type(v) == "string" or v>0) then
      return tostring(v)
   end
   return ""
end


function pt(t, msg)
   if msg then
      print(string.format('%s:',msg))
   end
   for k,v in pairs(t) do
      print(string.format("%s = %s", k, v))
   end
end


function pl(t, msg)
   if msg then
      print(msg .. ":")
   end
   for i = 1, #t do
      print(t[i])
   end
end


function update(t, t2, parent)
   for k,v in pairs(t2) do
      if v == "default" then
         if parent ~= nil then
            v = parent[k]
         else
            goto continue
         end
      elseif v == "ignored" then
         goto continue
      else
         t[k] = v
      end
      ::continue::
   end
   return t
end


Item = {}

function Item:new(o)
   o = o or error("need a filled in object")
   self.__index = self
   setmetatable(o, self)
   return o
end

function Item:clear()
   if self.items then
      self.items = {}
      self.labels = {}
      self.accums = {}
      self.totals = {}
   end
end

function Item:setValue(name, val, parent)
   -- if name == "itemname" then
   --    print ("SetItemName '" .. name .. "'=" .. tostring(val))
   -- end
   if val=="ignored" then
      return val
   end
   if val=="default" and parent ~= nil then
      self:setValue(name, parent[name])
   else
      t = self
      if self.totalNames and self.totalNames[name] then
         t = self.totals
      end
      t[name] = val
   end
end

function Item:setTerm(term)
   self:setValue("term", term, self.parent)
   if term ~= nil then
      self.year = (term+1) // 2
   else
      self.year = nil
   end
   return term
end

function Item:setType(t)
   -- экзамен, зачет, зачет с оценкой, тест,
   -- контрольная работа
   return self:setValue("type", t, self.parent)  -- TODO assign correct UUID
end

function Item:setVals(h, parent)
   update(self, h, parent)
end

function Item:sprintItemName()
   if self.name then
      name = self.itemname
   else
      name = self:getName(self.type)  -- default if any
   end
   tex.sprint('\\def\\itemname{' .. name .. '}%\n')
end

function Item:sprintRDFTypes()
   t = self.rdftype
   if t == nil then
      return
   else
      for i = 1, #t do
         ty = " !wpdd:" .. t[i] .. " "
         tex.sprint(ty)
         -- error(ty)
         print(ty)
      end
   end
end

function Item:sprintTitle(emph, titlename)
   -- pt(self, "SELF:")
   tex.sprint("\\" .. titlename .. "name~\\the" .. titlename .. ".~")
   if emph then
      tex.sprint("\\" .. emph .. "{")
   end
   tex.sprint(self.title)
   if emph then
      tex.sprint("}")
   end
   tex.sprint("\\par")
end

function Item:setType(t, name, parent)
   self:setValue("type", t, parent)
   self:setItemName(name, parent)
end

function Item:setItemName(name, parent)
   if name == nil then
      name = self:getItemName(self.type)
   end
   return self:setValue("itemname", name, parent)
end


function Item:setTotalNames(tbl)
   if tbl==nil then return end
   t = {}
   for i = 1, #tbl do
      n = tbl[i]
      t[n] = true
   end
   self.totalNames = t
   return t
end

function Item:getItemName(t)
   d = {
      topic = "Тема"
   }
   n = d[t]
   if n==nil then
      n = t
   end
   return n
end

function Item:print()
   print("Item: ------------------")
   pt(self, "self")
   if self.items then
      pt(self.items, "items")
   end
   if self.labels then
      pt(self.labels, "labels")
   end
   if self.accums then
      pt(self.accums, "accums")
   end
   if self.totals then
      pt(self.labels, "totals")
   end
   print("------------------------")
end

function Item:asItems(totalNames)
   self.items = {}
   self.labels = {}
   self.accums = {}
   self.totals = {}
   self:setTotalNames(totalNames)
   return self
end

function Item:addItem(item, totalNames)
   if self.items == nil then  -- initialize as Items
      self:asItems(totalNames)
   end

   table.insert(self.items, item)
   item.parent = self
   l = self.labels
   if item.label ~= nil then
      l[item.label] = item
   end
   -- l[topic.index] = item
   t = self.accums
   tn = self.totalNames or {} -- TODO: hack
   for n, _ in pairs(tn) do  -- accumulate
      t[n] = (t[n] or 0) + (item[n] or 0)
   end
   -- pt(topic, "Added")
   -- pt(t, "Accumulated")
end

function Item:getLabel(name) -- return labels for a total name
   d = {
      lec = "Лекция",
      lab = "Лабораторная работа",
      per = "Самостоятельная работа",
      sem = "Саминар",
      pra = "Практическая работа"
   }
   return d[name]
end

function Item:getRDFType(name)
   pref = "wpdd:"
   d = {
      lec = "Lection",
      lab = "LaboratoryWork",
      per = "IndependentWork",
      sem = "Seminar",
      pra = "PracticalWork"
   }
   return pref .. d[name]
end

function Item:resetAccums()
   if self.accums then
      self.accums = {}
   end
end

function Item:setTotals(ctrl, val)
   tc = self.totals
   if val ~= nil then
      self:setTotal(ctrl, val)
   else
      update(tc, ctrl)
   end
end

function Item:setTotal(key, val)
   tc = self.totals
   tc[key] = val
   return val
end

function Item:validate()
   ts = self.accums
   cs = self.totals
   rc = {}
   tn = self.totalNames or {} -- TODO: hack
   for k, _ in pairs(tn) do
      v = self:validateOne(k, ts[k], cs[k])
      if v then
         table.insert(rc, v)
      end
   end
   return rc
end

function Item:validateOne(key, val, ctrl)
   d = val-ctrl
   if d==0 then return end
   if val>ctrl then
      return string.format("Суммарное значение %d атрибута '%s' БОЛЬШЕ чем нужно (%d) на %d", val, key, ctrl, d)
   else
      return string.format("Суммарное значение %d атрибута '%s' МЕНЬШЕ чем нужно (%d) на %d", val, key, ctrl, -d)
   end
end

function Item:topicValidation()
   -- pt(Topics)
   -- val = self:validate()
   val = {}  -- TODO: hack
   if #val > 0 then
      pref = "\\item \\color{red} "
      body = table.concat(val, "\n" .. pref)
      con = table.concat(val, "\nERROR: ")
      body = pref .. body
      con = "ERROR: " .. con
      prompt = "Итоговые значения не совпадают с плановыми"
      tex.sprint(string.format("\\begin{SyllabusValidation}{%s}", prompt))
      print(con)
      tex.sprint(body)
      tex.sprint("\\end{SyllabusValidation}")
   end
end


function Item:workValidation(total)
   total = total or self.totals[self.type]
   -- pt(Topics.totalsControl, "TOP")
   -- print(self.type)
   if total == nil then
      return print("ERROR: Тип студенческих работ не известен или не определен")
   end
   if self.total ~= total then
      tex.sprint(
         string.format(
            "\\paragraph{\\color{red} Количество часов не совпадает (%s) }", self.type))
      d = self.total - total
      if d>0 then
         tex.sprint(
            string.format(
               "{\\bfseries \\color{red} суммарное количество (%u) БОЛЬШЕ целевого (%u) на %d}\\par",
               self.total, total, d))
      else
         tex.sprint(
            string.format(
               "{\\bfseries \\color{red} суммарное количество (%u) МЕНЬШЕ целевого (%u) на %d}\\par",
               self.total, total, -d))
      end
   end
end

function Item:tprint(s)
   tex.print(s)
   print(s)
end

function Item:tsprint(s)
   tex.sprint(s)
   print(s)
end

function Item:generateContentByTopic()
   -- f = ALL.files["cbt"] -- ContentByTopic
   -- self:tsprint([[\renewcommand{\syll@contentbytopic}[0]{]])
   self:tprint("%%%% PRINTING: ContentByTopic %%%%%%")
   self:tprint("\\def\\itemname{" .. self.itemname .. "}%")
   self:tprint([[\begin{tblr}{|X[4,l]|X[1,c]|X[1,c]|X[1,c]|X[1,c]|X[1,c]|X[2,l]|}
  \hline
  \SetCell[r=3]{c} Раздел дисциплины~/ тема &
  \SetCell[r=3]{c} Семес. &
  \SetCell[c=4]{c} Виды учебной работы & & & &
  \SetCell[r=3]{l} Формы текущего контроля; Формы промежут. аттестации \\\hline
  & &  \SetCell[c=3]{c,4.4cm} Контактная работа преподавателя с обучающимися & & &
  \SetCell[r=2]{c} Самост. работа & \\ \hline
  & &  Лекции & Лаб. занятия & Практ. занятия & & \\\hline]])
   for i=1, #self.items do
      s = ""
      t = self.items[i]
      s = s .. ("\\itemname~")
      s = s .. (soe(t.index) .. ".~" .. t.title .. " & ")
      s = s .. (soe(t.term) .. " & ")
      s = s .. (soe(t.lec) .. " & ")
      s = s .. (soe(t.lab) .. " & ")
      s = s .. (soe(t.sem) .. " & ")
      s = s .. (soe(t.per) .. " & ")
      s = s .. (self.control .. " \\\\\\hline")
      self:tprint(s)
   end
   c = self.totals
   s = (string.format([[\SetCell[c=2]{c}Итого (%s семестр) & & %s & %s & %s
   & %s & %s \\\hline]],
   soe(self.term),
   soe(c.lec),
   soe(c.lab),
   soe(c.sem),
   soe(c.per),
   soe(self.testing)))
   self:tprint(s)
   self:tprint("\\end{tblr}")
   -- s = s .. ("}\n")
   -- self:tprint("CONTENT BY TOPIC\n")
end


function readBuf(buf)
   if ALL.readObj ~= nil and ALL.readObj.c ~= nil then
      ALL.readObj.c:appendBuf(buf)
   end
end

function Item:startReading()
   self.buffer = {}
   ALL.readObj = { c=self,
                   p=ALL.readObj}
   luatexbase.add_to_callback('process_input_buffer', readBuf, 'readbuf')
   return self
end

function Item:stopReading()
   c = ALL.readObj.c
   p = ALL.readObj.p
   ALL.readObj = p
   if p == nil then
      luatexbase.remove_from_callback('process_input_buffer', 'readbuf')
   else
      p.c:appendBuf(c.buffer) -- Include as a sub-buffer in the buffer
   end
   ALL.bufferRead = c.buffer
   self:printBuffer()
   return c
end

function Item:printBuffer(buf)
   if buf == nil then
      buf = self.buffer
   end
   tmp = {}
   print("Lua: ------")
   for k,v in pairs(buf) do
      if type(v) == "table" then
         print("subbuf: " .. tostring(v))
         self:printBuffer(v)
      else
         print(v)
      end
   end
   print("------")
end

function Item:bufferToJSON(buf, nodetype)
   -- Having buffer consisting list of strings and tables
   -- Convert to JSON
   if buf == nil then
      buf = self.buffer
      nodetype = self.type
   end
   if nodetype then
      s = string.format([[{"type":"%s",]], self.type)
   else
      s = "{"
   end
   s = s .. "\"buffer\":[\n"
   for k, v in pairs(buf) do
      -- print(k, "=", v)
      if type(v) == "table" then
         s = s .. self:bufferToJSON(v)
      else
         v = string.gsub(v, [[\]], [[\\]])
         v = string.gsub(v, [["]], [[\"]])
         s = s .. [["]] .. v .. [["]]
      end
      s = s .. ",\n"
   end
   s = s .. [[""]]
   s = s .. "]}"
   -- print(s)
   return s
end

function mqe(msg)
   print("ERROR connection to RabbitMQ server", msg)
end

function Item:connectMQ(connection, host, port)
   function e(msg)
      mqe(msg)
   end

   if connection == nil then
      connection = {
         username = "lib",
         password = "lib@rabbitmq",
         vhost = "/"
      }
   end

   if host == nil then host = "irnok.net" end
   if port == nil then port = "15672" end -- 5672?
   self._connection = connection
   self._mq, err = mq:new(connection)
   mq = self._mq
   if err ~= nil then
      e(msg)
   else
      mq:set_timeout(500) -- timeout in microseconds
      ok, err = mq:connect(host, port)
      if err ~= nil then
         e(msg)
      end
   end
end

function Item:sendBuffer(strbuf, chan)
   mq = self._mq
   if mq ~= nil then
      headers = {}
      headers["content-type"] = "application/json"
      mq:send(strbuf, headers)
      mqe("Connection is not established")
   end
end

function Item:disconnMQ()
   mq = self._mq
   if mq ~= nil then
      mq:close()
   else
      mqe("Connection is not established")
   end
end

function Item:appendBuf(buf)
   table.insert(self.buffer, buf)
end

-- ALL.saveState = saveState
-- ALL.restoreState = restoreState

function openFile(filename, ext)
   f=io.open(filename .. "." .. ext, "w")
   ALL[ext] = f
   f:write("\\relax\n")
   -- f:write("\\MakeAtLetter\n")
   -- f:write([[\gdef\a@aa{HELLO!\par}]])
   ALL.files[ext] = f
   return f
end

function closeFile(ext)
   -- ALL.f:write("\MakeAtOther\n")
   f = ALL.files[ext]
   f:close()
   ALL.files[ext] = nil
end


function getTable(name)
   prev = ALL.prev
   if prev ~= nil then
      prev = prev[name]
      if prev ~= nil then
         prev = Item:new(prev)
      end
   end
   return prev
end

function generateContentByTopic()
   topics = getTable('topic')
   if topics then
      topics:generateContentByTopic()
   else
      tex.print("ERROR: Не найдено таблицы 'topic'")
   end
end

ALL.Item = Item
ALL.pt = pt
ALL.pl = pl
ALL.openFile = openFile
ALL.closeFile = closeFile
ALL.files={}
ALL.content={}
-- ALL.tbl=tbl
ALL.generateContentByTopic=generateContentByTopic



return ALL
