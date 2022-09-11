#!/usr/bin/env python
import pika
import json

JSON = r"""{"buffer":[
    "    \\item Ландау Л. Д. Теоретическая физика [Текст] : учеб. пособие для студ. физ. спец. ун-тов : в 10 т. / Л. Д. Ландау, Е. М. Лифшиц. - 8-е изд., стер. - М. : Физматлит. - 22 см. Т. 2 : Теория поля / ред. Л. П. Питаевский. -- 2012. -- 533 с.",
    "    \\item Леоненков А. Самоучитель UML 2 [текст] / А. Леоненков, 2010. -- 576 с. Неог. \\label{b1}",
    "    \\item Буч Г. Язык UML. Руководство пользователя [текст], 2008. -- 496 с. Неог. \\label{b2}",
    "    \\item Розенберг Д. Применение объектного моделирования с использованием UML и анализ прецедентов [текст], 2007. -- 160 с. Неог. \\label{b3}",
    "    \\item Антониоу Г. Семантический веб [текст], 2016. -- 240 с. Неог. \\label{b4}",
    "    \\item Цуканова Н. И. Теория и практика логического программирования на языке Visual Prolog 7. Учебное пособие для вузов [текст] / Н. И. Цуканова, Т. А. Дмитриева, 2013. -- 232 с. Неог. \\label{b5}",
    "    \\item Марков В.Н. Современное логическое программирование на языке Visual Prolog 7.5 [текст] / В.Н. Марков, 2016. -- 544 с. Неог. \\label{b6}",
    "    \\end{referencelist}",
    ""]}"""

JSON = r"""{"buffer":[
    "    \\item Ландау Л. Д. Теоретическая физика [Текст] : учеб. пособие для студ. физ. спец. ун-тов : в 10 т. / Л. Д. Ландау, Е. М. Лифшиц. - 8-е изд., стер. - М. : Физматлит. - 22 см. Т. 2 : Теория поля / ред. Л. П. Питаевский. -- 2012. -- 533 с.\\label{landauOOO}\\label{book86} % My comment \\% No comment\n % Another comment\n",
    "    \\end{referencelist}",
    ""]}"""

EXCHANGE_NAME = "lib-exchange"

connection = pika.BlockingConnection(pika.ConnectionParameters('irnok.net'))
channel = connection.channel()

def enqueue_raw_json(json):

    # channel.queue_declare(queue='lib', durable=True)

    channel.basic_publish(exchange=EXCHANGE_NAME,
                          routing_key='raw.lib.json',
                          body=json,
                          mandatory=True)
    print(" [x] Sent {}".format(json))


def enqueue_triple(rec, ident):
    msg = {"id": str(ident), "buffer": rec}
    channel.basic_publish(exchange=EXCHANGE_NAME,
                          routing_key='triple.lib.json',
                          body=json.dumps(msg, ensure_ascii=False),
                          mandatory=True)
    print(" [x] Triple Sent {}".format(msg))



def close_connection():
    connection.close()



if __name__ == "__main__":
    # enqueue_raw_json(JSON)
    enqueue_triple("""Фалалеев,  Михаил  Валентинович.  Математический  анализ  :  учеб.пособие  для студ.  вузов.  обуч.  по  напр.  подгот.  \"Математика\",  \"Прикладная  математика  и информатика\",  \"Информационная  безопасность\":  в  4  ч.  /  М.  В.  Фалалеев  ;  рец.:  Н.  А. Сидоров,  А.  А.  Щеглова  ;  Иркутский  гос.  ун-т,  Ин-т  мат.,  эконом.иинформ.  -  Иркутск  : Изд-во ИГУ, 2013. - ISBN 978-5-9624-0822-4. Ч. 2. - 2013. - 139 с. - ISBN 978-5-9624- 0824-""", "156d3468-31b1-11ed-b3ea-704d7b84fd9f")
    close_connection()
