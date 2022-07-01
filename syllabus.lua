json = require("json")

ALL = {}

-- print("\n\n-------->", _VERSION, "\n\n")

function soe(v) -- string or empty
   if v~=nil and v>0 then
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
      print(msg, ":")
   end
   for i = 1, #t do
      print(t[i])
   end
end


function update(t, t2)
   for k,v in pairs(t2) do
      t[k] = v
   end
   return t
end


Item = {
   items = {}
   labels = {}
}


function Item:print()
   print("Item: ------------------")
   pt(self, "self")
   pt(self.items, "items")
   pt(self.labels, "labels")
   print("------------------------")
end

function Item:clear()
   self.items = {}
   self.labels = {}
end

function Item:openFile(filename, ext)
   f=io.open(filename .. "." .. ext, "w")
   ALL[ext] = f
   f:write("\\relax\n")
   -- f:write("\\MakeAtLetter\n")
   -- f:write([[\gdef\a@aa{HELLO!\par}]])
end


function Item:closeFile(ext)
   -- ALL.f:write("\MakeAtOther\n")
   f = ALL[ext]
   f:close()
   ALL[ext] = nil
end


function Item:setValue(name, val)
   if val=="undefined" then
      return val
   end
   self[val] = val
end

function Item:setTerm(term)
   self:setValue("term", term)
   if term ~= nil then
      self.year = (term+1) // 2
   end
   return term
end

function Item:setType(t)
   -- экзамен, зачет, зачет с оценкой, тест,
   -- контрольная работа
   return self:setValue("type", t)  -- TODO assign correct UUID
end



Items = {
   __index = Item
   totals = {}
   accuns = {}
   totalNames = {}
}

setmetatable(Items, Item)

function Items:print()
   print("Item: ------------------")
   pt(self, "self")
   pt(self.items, "items")
   pt(self.labels, "labels")
   pt(self.labels, "accums")
   pt(self.labels, "totals")
   print("------------------------")
end

function Items:addItem(item)
   table.insert(self.items, item)
   l = self.labels
   if topic.label ~= nil then
      l[topic.label] = item
   end
   l[topic.index] = item
   t = self.accums
   -- pt(topic, "TOPIC")
   -- pt(t, "TOTALS")
   tn = self:getTotalNames()
   for i = 1, #tn do  -- accumulate
      n = tn[i]
      t[n] = (t[n] or 0) + (item[n] or 0)
   end
   -- pt(topic, "Added")
   -- pt(t, "Accumulated")
end


function Items:getTotalNames()
   return self.totalNames
end

function Items:getLabel(name) -- return labels for a total name
   return {
      "lec" : "Лекция",
      "lab" : "Лабораторная работа",
      "per" : "Самостоятельная работа",
      "sem" : "Саминар",
      "pra" : "Практическая работа"
   } [name]
end

function Items:getRDFType(name)
   pref = "wpdd:"
   return "wpdd" .. {
      "lec" : "Lection",
      "lab" : "LaboratoryWork"
      "per" : "IndependentWork"
      "sem" : "Seminar"
      "pra" : "PracticalWork"
   }[name]
end

function Items:resetAccums()
   self.accums = {}
end

function Items:setTotals(ctrl, val)
   tc = self.totals
   if val ~= nil then
      self:setTotal(ctrl, val)
   else
      update(tc, ctrl)
   end
end

function Items:setTotal(key, val)
   tc = self.totals
   tc[key] = val
   return val
end

function Items:validate()
   ts = self.accums
   cs = self.totals
   rc = {}
   tn = self:getTotalNames()
   for i = 1, #tn do
      k = tn[i]
      v = self:validateOne(k, ts[k], cs[k])
      if v then
         table.insert(rc, v)
      end
   end
   return rc
end

function Items:validateOne(key, val, ctrl)
   d = val-ctrl
   if d==0 then return end
   if val>ctrl then
      return string.format("Суммарное значение %d атрибута '%s' БОЛЬШЕ чем нужно (%d) на %d", val, key, ctrl, d)
   else
      return string.format("Суммарное значение %d атрибута '%s' МЕНЬШЕ чем нужно (%d) на %d", val, key, ctrl, -d)
   end
end


function Items:validation()
   -- pt(Topics)
   val = self:validate()
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





Topics = {
   __index = Topics
   totalNames = {"lec", "lab", "sem", "per"}
}

setmetatable(Topics, Items)

function Topics:getTotalNames()
   return self.totalNames
end

function Topics:generate()
   f = ALL["cbt"] -- ContentByTopic
   -- f:write([[\renewcommand{\syll@contentbytopic}[0]{]])
   f:write([[\begin{tblr}{|X[4,l]|X[1,c]|X[1,c]|X[1,c]|X[1,c]|X[1,c]|X[2,l]|}
  \hline
  \SetCell[r=3]{c} Раздел дисциплины~/ тема &
  \SetCell[r=3]{c} Семес. &
  \SetCell[c=4]{c} Виды учебной работы & & & &
  \SetCell[r=3]{l} Формы текущего контроля; Формы промежут. аттестации \\\hline
  & &  \SetCell[c=3]{l,4cm} Контактная работа преподавателя с обучающимися & & &
  \SetCell[r=2]{c} Самост. работа & \\ \hline
  & &  Лекции & Лаб. занятия & Практ. занятия & & \\\hline]])
   f:write("\n")
   for i=1, #self.items do
      t = self.items[i]
      f:write("\\topicname~")
      f:write(soe(t.index) .. ".~" .. t.title .. " & ")
      f:write(soe(t.term) .. " & ")
      f:write(soe(t.lec) .. " & ")
      f:write(soe(t.lab) .. " & ")
      f:write(soe(t.sem) .. " & ")
      f:write(soe(t.per) .. " & ")
      f:write(Topics.control .. " \\\\\\hline\n")
   end
   cc = self.totals
   c = {}
   for k,v in pairs(cc) do
      c[k] = soe(v)
   end

   cc=nil

   f:write(string.format([[\SetCell[c=2]{c}Итого ({%s} семестр) & & %s & %s & %s
  & %s & %s \\\hline]],
   soe(self.term),
   c.lec,
   c.lab,
   c.sem,
   c.per,
   soe(self.type)))
   f:write("\n\\end{tblr}")
   -- f:write("}\n")
end


function Totals:clear()
   self.items = {}
   self.labels = {}
   self.accums = {}
   self.totals = {}
end

Works = {
   works = {},
   labels = {},
   total = 0
}

Works.__index = Works
setmetatable(Works, Items)


-- TODO: Continue refatoring

function Works:setType(t, name)
   if t=='nil' then t=nil end
   self.type = t
   self:setName(name)
end

function Works:setName(name)
   print(self)
   if name then
      self.name = name
   else
      self.name = self:getName(self.type)
   end
end

function Works:sprintWorkName()
   if self.name then
      name = self.name
   else
      name = self:getName(self.type)  -- default if any
   end
   tex.sprint(string.format('\\def\\workname{%s}', name))
end

function Works:sprintRDFType()
   tex.sprintRDFType("!" .. self:getRDFType(self.type))
end

function Works:addWork(w)
   table.insert(self.works, w)
   -- pt(w, "WORK")
   self.total = self.total + w.hours
   if w.label then
      self.labels[w.label] = w
   end
   self.labels[w.index] = w
end


function Works:validation(total)
   total = total or Topics.totalsControl[self.type]
   -- pt(Topics.totalsControl, "TOP")
   -- print(self.type)
   if total == nil then
      return error("Type is unknown and total is empty too")
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

Topic = {}

function Topic:new(o)
   o = o or error("need a filled in object")
   o.topicName = o.topicName or "Тема"
   update(o, __hours)
   if o.kw then
      update(o, o.kw)
   end
   o.kw = nil
   self.__index = self
   setmetatable(o, self)
   self:setTerm("default")
   return o
end

function Topic:setTerm(term)
   if term == "default" then
      term = Topics.term
   end
   self.term = term
   if term ~= nil then
      self.year = (term+1) // 2
   else
      self.year = nil
   end
end

function Topic:setLabel(label)
   if label == "undefined" then
      return
   end
   self.label = label
end

function Topic:setHours(h)
   update(self, h)
end

function Topic:print()
   pt(self)
end

function Topic:sprintTitle(emph)
   -- pt(self, "SELF:")
   tex.sprint("\\topicname~\\thetopic.~")
   if emph then
      tex.sprint("\\" .. emph .. "{")
   end
   tex.sprint(self.title)
   if emph then
      tex.sprint("}")
   end
   tex.sprint("\\par")
end

Work = {}

function Work:new(o)
   o = o or error("need a filled in object")
   if o.kw then
      update(o, o.kw)
   end
   o.kw = nil
   self.__index = self
   setmetatable(o, self)
   setmetatable(self, Topic)
   return o
end



function Work:setComp(comp)
   if comp then
      self.comp = comp
   else
      self.comp = Works.comp
   end
end

function Work:setTopics(topics)
   self.topics = topics
end

function saveState(filename)
   print("SAVE:", Topics:dump())
end


ALL.saveState = saveState
ALL.restoreState = restoreState

ALL.Topic = Topic
ALL.Topics = Topics
ALL.Works = Works
ALL.Work = Work
ALL.pt = pt



return ALL
