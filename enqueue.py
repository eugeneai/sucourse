#!/usr/bin/env python
import pika

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


def enqueue(json):
    connection = pika.BlockingConnection(pika.ConnectionParameters('irnok.net'))
    channel = connection.channel()

    # channel.queue_declare(queue='lib', durable=True)

    channel.basic_publish(exchange=EXCHANGE_NAME,
                          routing_key='raw.lib.json',
                          body=json,
                          mandatory=True)
    print(" [x] Sent {}".format(json))
    connection.close()


if __name__ == "__main__":
    enqueue(JSON)
