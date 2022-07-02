json = require("json")

ALL = {}

-- print("\n\n-------->", _VERSION, "\n\n")

function soe(v) -- string or empty
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
      self[name] = val
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

function Item:sprintRDFType()
   tex.sprintRDFType("!" .. self:getRDFType(self.type))
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
   self.totalNames = totalNames
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
   for i = 1, #tn do  -- accumulate
      n = tn[i]
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
   for i = 1, #tn do
      k = tn[i]
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

function Item:generateContentByTopic()
   f = ALL.files["cbt"] -- ContentByTopic
   -- f:write([[\renewcommand{\syll@contentbytopic}[0]{]])
   f:write("\\def\\itemname{" .. self.itemname .. "}%\n")
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
      f:write("\\itemname~")
      f:write(soe(t.index) .. ".~" .. t.title .. " & ")
      f:write(soe(t.term) .. " & ")
      f:write(soe(t.lec) .. " & ")
      f:write(soe(t.lab) .. " & ")
      f:write(soe(t.sem) .. " & ")
      f:write(soe(t.per) .. " & ")
      f:write(self.control .. " \\\\\\hline\n")
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


--   totalNames = {"lec", "lab", "sem", "per"}


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




ALL.Item = Item
ALL.pt = pt
ALL.pl = pl
ALL.openFile = openFile
ALL.closeFile = closeFile
ALL.files={}

return ALL
