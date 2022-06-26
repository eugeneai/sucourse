ALL = {}

-- print("\n\n-------->", _VERSION, "\n\n")

__hours = {
      lec=0,
      lab=0,
      sem=0,
      per=0
   }

Topics = {
   topics = {},
   totals = __hours,
   totalsControl = {
      lec=0,
      lab=0,
      sem=0,
      per=0
   },
   labels = {}
}

function pt(t, msg)
   if msg then
      print(msg, ":")
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

function Topics:addTopic(topic)
   table.insert(self.topics, topic)
   l = self.labels
   if topic.label ~= nil then
      l[topic.label] = topic
   end
   l[topic.index] = topic
   t = self.totals
   t.lec = t.lec + topic.lec
   t.lab = t.lab + topic.lab
   t.sem = t.sem + topic.sem
   t.per = t.per + topic.per
   -- pt(topic, "Added")
   -- pt(t, "Accumulated")
end

function Topics:setControl(ctrl, val)
   tc = self.totalsControl or {}
   if val ~= nil then
      tc[ctrl] = val
   else
      update(tc, ctrl)
   end
   self.totalsControl = tc
end


function Topics:setControlKey(key, val)
   tc = self.totalsControl or {}
   tc[key] = val
   self.totalsControl = tc
end

function Topics:validate()
   ts = self.totals
   cs = self.totalsControl
   rc = {}
   for k,_ in pairs(__hours) do
      v = Topics:validateOne(k, ts[k], cs[k])
      if v then
         table.insert(rc, v)
      end
   end
   return rc
end

function Topics:validateOne(key, val, ctrl)
   d = val-ctrl
   if d==0 then return end
   if val>ctrl then
      return string.format("Суммарное значение %d переменной '%s' БОЛЬШЕ чем нужно (%d) на %d", val, key, ctrl, d)
   else
      return string.format("Суммарное значение %d переменной '%s' МЕНЬШЕ чем нужно (%d) на %d", val, key, ctrl, -d)
   end
end

function Topics:validation()
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

function Topics:print()
   pt(self, "TOPICS:")
   pt(self.totals, "TOTALS:")
   pt(self.totalsControl, "CONTROL:")
   pt(self.labels, "LABELS:")
end

Works = {
   works = {},
   labels = {},
   total = 0
}

Works.__index = Works
setmetatable(Works, Topics)

function Works:clear()
   self.works={}
   self.label={}
   self.total=0
   self.type = nil
   self.name = nil
   self.term = nil
   self.comp = nil
end


function Works:getName(t)
   if t=="lec" then
      return "Лекция"
   elseif t=="lab" then
      return "Лабораторная работа"
   elseif t=="per" then
      return "Самостоятельная работа"
   elseif t=="sem" then
      return "Саминар"
   elseif t=="pra" then
      return "Практическая работа"
   end
end

function Works:getRDFType(t)
   pref = "wpdd:"
   if t=="lec" then
      return pref .. "Lection"
   elseif t=="lab" then
      return pref .. "LaboratoryWork"
   elseif t=="per" or t=="ind" then
      return pref .. "IndependentWork"
   elseif t=="sem" then
      return pref .. "Seminar"
   elseif t=="pra" then
      return pref .. "PracticalWork"
   end
end

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
   return o
end

function Topic:setTerm(term)
   self.term = term
   self.year = (term+1) // 2
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



ALL.Topic = Topic
ALL.Topics = Topics
ALL.Works = Works
ALL.Work = Work
ALL.pt = pt

return ALL
