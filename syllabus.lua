ALL = {}

Topics = {
   topics = {},
   totals = {
      lec=0,
      lab=0,
      pra=0,
      per=0
   },
   totalsControl = {
      lec=0,
      lab=0,
      pra=0,
      per=0
   }
}

function Topics:addTopic(topic)
   table.insert(self.topics, topic)
   self.lec = self.lec + topic.lec
   self.lab = self.lab + topic.lab
   self.pra = self.pra + topic.pra
   self.per = self.per + topic.per
end

function Topics:setControl(lec, lab, pra, per)
   tc = self.totalsControl
   tc.lec = lec
   tc.lab = lab
   tc.pra = pra
   tc.per = per
end

Topic = {}

function Topic:new(index, title, content, label)
   local t = {
      index=index,
      title=title,
      content=content,
      label=label
   }
   print(index, title, content, label)
   -- t.__index = self
   -- return setmetatable(t, self)
end

function Topic:setTerm(term)
   self.term = term
   self.year = (term+1) // 2
end

function Topic:hours(lec, lab, pra, per, con)
   self.lec = lec
   self.lab = lab
   self.pra = pra
   self.per = per
   self.con = con
end


ALL.Topic = Topic
ALL.Topics = Topics

return ALL
