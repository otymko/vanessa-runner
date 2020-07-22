﻿
#Область ОбработчикиСобытийФормы

&НаСервере
Процедура ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)
	
	Попытка
		Выполнить("ОбщегоНазначения.ХранилищеОбщихНастроекСохранить(""ОбщиеНастройкиПользователя"",
					|""ЗапрашиватьПодтверждениеПриЗавершенииПрограммы"", Ложь);");
	Исключение
		ТекстСообщения = НСтр("ru = 'Неудача в УбратьПодтверждениеПриЗавершенииПрограммы'");
		ЗаписатьВЖурналРегистрации(ТекстСообщения);
	КонецПопытки;

КонецПроцедуры

&НаКлиенте
Процедура ПриОткрытии(Отказ)
	
	Попытка
		
		ПараметрЗапускаФормы = СокрЛП(ПараметрЗапуска);
		Если ПустаяСтрока(ПараметрЗапускаФормы) Тогда	
			ТекстСообщения = СтрШаблон(НСтр("ru = 'Ни передано ни одного параметра запуска'"));
			ОбщегоНазначенияКлиентСервер.СообщитьПользователю(ТекстСообщения);
			ЗаписатьВЖурналРегистрации(ТекстСообщения);
			
			ПрекратитьРаботуСистемы(Ложь);	
		КонецЕсли;
		
		ТекстСообщения = НСтр("ru = 'Запуск обработчиков ожидания...'");
		ОбщегоНазначенияКлиентСервер.СообщитьПользователю(ТекстСообщения);
		
		МожноЗавершатьРаботу = Ложь;
		ЗапуститьОбработкуПараметров();
		
	Исключение
				
		ТекстСообщения = СтрШаблон(НСтр("ru = 'Неудача при обработке параметров запуска
				|Параметры: %1
				|%2'"), ПараметрЗапускаФормы, ОписаниеОшибки());
		ЗаписатьВЖурналРегистрации(ТекстСообщения);
		
	КонецПопытки;

	ПрекратитьРаботуСистемы(Ложь);
			
КонецПроцедуры

#КонецОбласти

#Область ОбработчикиКомандФормы

&НаКлиенте
Процедура Запустить(Команда)
	
	ЗапуститьОбработкуПараметров();	
	
КонецПроцедуры

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

&НаКлиенте
Процедура ЗапуститьОбработкуПараметров()
	
	МассивПараметров = СтроковыеФункцииКлиентСервер.РазложитьСтрокуВМассивПодстрок(ПараметрЗапускаФормы, ";");
	
	Для Каждого Параметр Из МассивПараметров Цикл 	
		Попытка
			ЭтаФорма[Параметр] = Истина;
			ТекстСообщения = СтрШаблон(НСтр("ru = 'Прочитан параметр: %1'"), Параметр);
		Исключение			
			ТекстСообщения = СтрШаблон(НСтр("ru = 'Не установлен параметр запуска: %1'"), Параметр);	
			ЗаписатьВЖурналРегистрации(ТекстСообщения);
		КонецПопытки;
		ОбщегоНазначенияКлиентСервер.СообщитьПользователю(ТекстСообщения);
	КонецЦикла;
	
	Если МассивПараметров.Количество() = 0 Тогда
		ЗавершитьРаботуСистемы(Ложь);
	КонецЕсли; 
		
	Если МассивПараметров.Количество() > 1 И ОтключитьРегламентноеЗадание Тогда 
		НаименованиеРегламентногоЗадания = СокрЛП(МассивПараметров[1]);	
		ОтключитьРегламентноеЗадание();	
	КонецЕсли;	
	
	Если РазрешитьРаботуСВнешнимиРесурсами Или ЗапретитьРаботуСВнешнимиРесурсами Тогда 
		РаботаСВнешнимиРесурсами();		
	КонецЕсли;
		
	ПроверитьВозможностьЗакрытия();

КонецПроцедуры

&НаСервере
Процедура ОтключитьРегламентноеЗадание()
	
	Отбор = Новый Структура("Метаданные", НаименованиеРегламентногоЗадания);
	СписокЗаданий = РегламентныеЗаданияСервер.НайтиЗадания(Отбор);
	
	ПараметрыЗадания = Новый Структура("Использование", Ложь);
	
	Для Каждого РегламентноеЗадание Из СписокЗаданий Цикл
		
		РегламентныеЗаданияСервер.ИзменитьЗадание(РегламентноеЗадание, ПараметрыЗадания);
		
		ТекстСообщения = СтрШаблон(НСтр("ru = 'Отключено регламентное задание: %1'"), РегламентноеЗадание.Наименование);
		ОбщегоНазначенияКлиентСервер.СообщитьПользователю(ТекстСообщения);
		
	КонецЦикла;
	МожноЗавершатьРаботу = Истина;
	
КонецПроцедуры	

&НаСервере
Процедура РаботаСВнешнимиРесурсами() 
	
	Если РазрешитьРаботуСВнешнимиРесурсами Тогда                            
		БлокировкаРаботыСВнешнимиРесурсами.РазрешитьРаботуСВнешнимиРесурсами();
		ТекстСообщения = НСтр("ru = 'Разрешена работа с внешними ресурсами'");
	ИначеЕсли ЗапретитьРаботуСВнешнимиРесурсами Тогда 
		БлокировкаРаботыСВнешнимиРесурсами.ЗапретитьРаботуСВнешнимиРесурсами();
		ТекстСообщения = НСтр("ru = 'Запрещена работа с внешними ресурсами'");
	КонецЕсли;	
	ОбщегоНазначенияКлиентСервер.СообщитьПользователю(ТекстСообщения);
	МожноЗавершатьРаботу = Истина;
		
КонецПроцедуры

&НаКлиенте
Процедура ПроверитьВозможностьЗакрытия()
	
	Если МожноЗавершатьРаботу И ЗавершитьРаботуСистемы Тогда
		ТекстСообщения = НСтр("ru = 'Завершаем работу'");
		ОбщегоНазначенияКлиентСервер.СообщитьПользователю(ТекстСообщения);	
	Иначе 
		ТекстСообщения = НСтр("ru = 'Не удалось обработать условия завершения работы. 
				| Вероятно обработка параметров не была выполнена. 
				| Завершаем работу не штатно!'");
		ОбщегоНазначенияКлиентСервер.СообщитьПользователю(ТекстСообщения);
	КонецЕсли;
	ЗавершитьРаботуСистемы(Ложь);
	
КонецПроцедуры

&НаСервере
Процедура ЗаписатьВЖурналРегистрации(Комментарий);
	ЗаписьЖурналаРегистрации(КлючЖР(), УровеньЖурналаРегистрации.Ошибка, Неопределено, Неопределено, Комментарий);
КонецПроцедуры	
	
&НаСервере
Функция КлючЖР() 
	Возврат "VanessaRunner.БлокировкаРаботыСВнешнимиРесурсами";	
КонецФункции

#КонецОбласти
