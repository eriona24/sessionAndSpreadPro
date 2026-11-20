
//+------------------------------------------------------------------+
//|                                          SessionAndSpreadPro.mq5 |
//|                                  Copyright 2026, MQL5 Developer  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026"
#property version   "1.00"
#property indicator_chart_window
#property indicator_plots 0

//--- Parametrat (Inputs)
input string   InpSection1       = "=== Oraret e Sesioneve (Ora e Serverit) ===";
input int      InpAsiaStart      = 0;        // Fillimi i Azise (Ora)
input int      InpAsiaEnd        = 8;        // Mbarimi i Azise (Ora)
input color    InpAsiaColor      = clrDarkSlateGray; // Ngjyra e Azise

input int      InpLondonStart    = 8;        // Fillimi i Londres (Ora)
input int      InpLondonEnd      = 16;       // Mbarimi i Londres (Ora)
input color    InpLondonColor    = clrDarkBlue; // Ngjyra e Londres

input int      InpNYStart        = 13;       // Fillimi i New York (Ora)
input int      InpNYEnd          = 21;       // Mbarimi i New York (Ora)
input color    InpNYColor        = clrDarkGreen; // Ngjyra e New York

input string   InpSection2       = "=== Alarmi i Spread-it & Paneli ===";
input int      InpMaxSpread      = 35;       // Kufiri maksimal i Spread-it (Points)
input bool     InpEnableAlert    = true;     // Aktivizo njoftimin kur kalon kufirin
input int      InpDaysToDraw     = 5;        // Sa dite pas te vizatohen sesionet

datetime lastAlertTime = 0;
string   prefix        = "SSP_";

//+------------------------------------------------------------------+
int OnInit()
  {
   EventSetTimer(1);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
   ObjectsDeleteAll(0, prefix);
  }

//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   DrawSessions();
   UpdateDashboard();
   return(rates_total);
  }

//+------------------------------------------------------------------+
void OnTimer()
  {
   UpdateDashboard();
  }

//+------------------------------------------------------------------+
void DrawSessions()
  {
   datetime now = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(now, dt);
   dt.hour = 0; dt.min = 0; dt.sec = 0;
   datetime todayStart = StructToTime(dt);

   for(int d = 0; d < InpDaysToDraw; d++)
     {
      datetime dayBase = todayStart - d * 86400;
      DrawBox("Asia_" + IntegerToString(d), dayBase + InpAsiaStart * 3600, dayBase + InpAsiaEnd * 3600, InpAsiaColor);
      DrawBox("London_" + IntegerToString(d), dayBase + InpLondonStart * 3600, dayBase + InpLondonEnd * 3600, InpLondonColor);
      DrawBox("NY_" + IntegerToString(d), dayBase + InpNYStart * 3600, dayBase + InpNYEnd * 3600, InpNYColor);
     }
  }

//+------------------------------------------------------------------+
void DrawBox(string name, datetime t1, datetime t2, color clr)
  {
   string objName = prefix + name;
   int bar1 = iBarShift(_Symbol, _Period, t1, false);
   int bar2 = iBarShift(_Symbol, _Period, t2, false);
   if(bar1 < 0 || bar2 < 0) return;

   int count = bar1 - bar2 + 1;
   if(count <= 0) return;

   int highestBar = iHighest(_Symbol, _Period, MODE_HIGH, count, bar2);
   int lowestBar  = iLowest(_Symbol, _Period, MODE_LOW, count, bar2);
   if(highestBar < 0 || lowestBar < 0) return;

   double highPrice = iHigh(_Symbol, _Period, highestBar);
   double lowPrice  = iLow(_Symbol, _Period, lowestBar);

   if(ObjectFind(0, objName) < 0)
      ObjectCreate(0, objName, OBJ_RECTANGLE, 0, t1, highPrice, t2, lowPrice);
   else
     {
      ObjectSetInteger(0, objName, OBJPROP_TIME, 0, t1);
      ObjectSetDouble(0, objName, OBJPROP_PRICE, 0, highPrice);
      ObjectSetInteger(0, objName, OBJPROP_TIME, 1, t2);
      ObjectSetDouble(0, objName, OBJPROP_PRICE, 1, lowPrice);
     }

   ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, objName, OBJPROP_FILL, true);
   ObjectSetInteger(0, objName, OBJPROP_BACK, true);
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
  }

//+------------------------------------------------------------------+
void UpdateDashboard()
  {
   long currentSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   datetime barTime = iTime(_Symbol, _Period, 0);
   int secLeft = (int)((barTime + PeriodSeconds(_Period)) - TimeCurrent());
   if(secLeft < 0) secLeft = 0;

   int mins = secLeft / 60;
   int secs = secLeft % 60;
   string timerStr = StringFormat("%02d:%02d", mins, secs);

   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   string sessionStr = "Off-Peak";
   if(dt.hour >= InpLondonStart && dt.hour < InpNYStart) sessionStr = "LONDON";
   else if(dt.hour >= InpNYStart && dt.hour < InpLondonEnd) sessionStr = "LONDON + NY";
   else if(dt.hour >= InpNYStart && dt.hour < InpNYEnd) sessionStr = "NEW YORK";
   else if(dt.hour >= InpAsiaStart && dt.hour < InpAsiaEnd) sessionStr = "ASIA";

   color spreadClr = (currentSpread > InpMaxSpread) ? clrRed : clrLimeGreen;

   CreateLabel("Title",   "SESSION & SPREAD PRO", 20, 25, clrWhite, 10);
   CreateLabel("Session", "Sesioni: " + sessionStr, 20, 45, clrGold, 9);
   CreateLabel("Spread",  "Spread: " + IntegerToString(currentSpread) + " pts", 20, 63, spreadClr, 9);
   CreateLabel("Timer",   "Qiriu mbyllet: " + timerStr, 20, 81, clrSilver, 9);

   if(InpEnableAlert && currentSpread > InpMaxSpread && (TimeCurrent() - lastAlertTime) > 300)
     {
      Alert(_Symbol + " - KUJDES! Spread-i u rrit ne: " + IntegerToString(currentSpread) + " points!");
      lastAlertTime = TimeCurrent();
     }
  }

//+------------------------------------------------------------------+
void CreateLabel(string name, string text, int x, int y, color clr, int fontSize)
  {
   string objName = prefix + name;
   if(ObjectFind(0, objName) < 0)
      ObjectCreate(0, objName, OBJ_LABEL, 0, 0, 0);

   ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, objName, OBJPROP_TEXT, text);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, fontSize);
   ObjectSetString(0, objName, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
  }
