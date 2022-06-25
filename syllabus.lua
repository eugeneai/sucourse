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
   if topic.label then
      l = self.labels -- or {}
      l[topic.label] = topic
      self.labels = l
   end
   t = self.totals
   t.lec = t.lec + topic.lec
   t.lab = t.lab + topic.lab
   t.sem = t.sem + topic.sem
   t.per = t.per + topic.per
   pt(topic, "Added")
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

Topic = {}

function Topic:new(o)
   o = o or error("need a filled in object")
   o.topicName = o.topicName or "Тема"
   update(o, __hours)
   update(o, o.kw)
   pt(o, "OOOOO")
   pt(o.kw, "KW")
   o.kw = nil
   self.__index = self
   setmetatable(o, self)
   return o
end

function Topic:setTerm(term)
   self.term = term
   self.year = (term+1) // 2
end

function Topic:hours(h)
   update(self, h)
end

function Topic:print()
   pt(self)
end

function Topic:sprintTitle(emph)
   tex.sprint("\\topicname~\\thetopic.~")
   if emph then
      tex.sprint("\\" .. emph .. "{")
   end
   tex.sprint(self.title)
   if emph then
      tex.sprint("}")
   end
end

ALL.Topic = Topic
ALL.Topics = Topics
ALL.pt = pt

return ALL
