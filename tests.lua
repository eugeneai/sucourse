

sy = require("syllabus")

t = sy.Topic:new{index=1, title="Title", descr="Description", label="label"}

print("t:", t)
t:print()

t:setTopicName("ВодоРаздел")
