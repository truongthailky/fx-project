﻿//+------------------------------------------------------------------+
//|                                                Check WinLoss.mq4 |
//|                                                 Truong Hong Thai |
//|                                                   truonghongthai |
//+------------------------------------------------------------------+
#property copyright "Truong Hong Thai"
#property link      "truonghongthai"
#property version   "1.00"
#property strict

#define  MAGIC      669


input string CSVfileName   = "Test\\signal\\Check M30 MarAug.csv";
input bool   optimizeTPSL  = FALSE; //Toi uu TP/SL

input bool   switchBUYSELL = FALSE; //Switch BUY & SELL
input double lotSize       = 0.1;
extern double slPip        = 45;
extern double tpPip        = 60;

string CSV_SL_TP           = "Test\\Optimize TPSL\\H4.csv";
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CSLTP
{
private:
   string            m_Symbol;
   double            m_TP;
   double            m_SL;

public:
   CSLTP;
   void              setData(string symbol, double SL, double TP)
   {
      m_Symbol = symbol;
      m_TP     = TP;
      m_SL     = SL;
   }

   string            getSymbol()
   {
      return m_Symbol;
   }
   double            getTP()
   {
      return m_TP;
   }
   double            getSL()
   {
      return m_SL;
   }
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CSignal
{

private:
   datetime          m_OpenTime;
   string            m_Symbol;
   int               m_Type;

public:
   CSignal;
   void              setData(string openTime, string symbol, string type)
   {
      m_OpenTime  = StrToTime(openTime);
      StringToUpper(symbol);
      m_Symbol    = symbol;
      type == "BUY" ? m_Type = OP_BUY : m_Type = OP_SELL;
   }
   //---
   string            getSymbol()
   {
      return m_Symbol;
   }

   //---
   datetime          getOpenTime()
   {
      return m_OpenTime;
   }

   //---
   int               getType()
   {
      return m_Type;
   }

   void              clearData()
   {
      m_OpenTime  = D'2999.12.31 00:00';
      m_Symbol    = "";
      m_Type      = EMPTY;
   }

   void              switchBuySell()
   {
      if(m_Type == OP_BUY)
         m_Type = OP_SELL;
      else if(m_Type == OP_SELL)
         m_Type = OP_BUY;
      return;
   }
};

CSignal trendSignal[];
CSignal signalsOfThisSymbol[];
CSLTP   superOptimizedSLTP[];
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//--- create timer
   EventSetTimer(60);

   if(readCSV(CSVfileName, trendSignal)) return(INIT_FAILED);
   getFilteredSignal(trendSignal, signalsOfThisSymbol);

   if(optimizeTPSL)
   {
      if(readCSV(CSV_SL_TP, superOptimizedSLTP)) return(INIT_FAILED);;
      getOptimizedSLTPofThisSymbol(superOptimizedSLTP);
      PrintFormat("%s - SL: %d, TP: %d", Symbol(), (int)slPip, (int)tpPip);
   }

   if(switchBUYSELL)
      for(int i=0; i<ArraySize(signalsOfThisSymbol); i++)
         signalsOfThisSymbol[i].switchBuySell();

   if(ArraySize(signalsOfThisSymbol) == 0)
   {
      Print("No Signal for ", Symbol());
      return(INIT_FAILED);
   }
//---


   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//--- destroy timer
   EventKillTimer();

}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime timeOfZeroBar = 0;
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   if(timeOfZeroBar==iTime(Symbol(), Period(), 0))
      return;
   timeOfZeroBar=iTime(Symbol(), Period(), 0);
//--- main func
   setOrder(signalsOfThisSymbol);

}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
int readCSV(string fileName, CSignal &_trendSignal[])
{
   ResetLastError();
   int fileHandle = FileOpen(fileName, FILE_CSV|FILE_READ, ',');
   if(fileHandle<0)
   {
      Print("fileHandle ", fileHandle);
      Print("Unable to open file, error code: ", GetLastError());
      return 1;
   }

   int i=0;
   while(!FileIsEnding(fileHandle))
   {
      //--- write data to the array
      string date    =FileReadString(fileHandle);
      string symbol  =FileReadString(fileHandle);
      string type    =FileReadString(fileHandle);

      if(!isTypeRight(type))
      {
         Print(__FUNCTION__, " Line ", i, ", Order Type invalid");
         i++;
         continue;
      }
      ArrayResize(_trendSignal, i+1, 1000);
      _trendSignal[i].setData(date, symbol, type);
      i++;
   }
//--- close the file
   FileClose(fileHandle);
   PrintFormat("Data is read, file %s is closed", fileName);
   return 0;
}
//+------------------------------------------------------------------+
bool isTypeRight(string type)
{
   StringToUpper(type);
   if(type=="BUY" || type =="SELL")
      return true;
   else
      return false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int readCSV(string fileName, CSLTP &_OptimizedTPSL[])
{
   ResetLastError();
   int fileHandle = FileOpen(fileName, FILE_CSV|FILE_READ, ',');
   if(fileHandle<0)
   {
      Print("fileHandle ", fileHandle);
      Print("Unable to open file, error code: ", GetLastError());
      return 1;
   }

   int i=0;
   while(!FileIsEnding(fileHandle))
   {
      //--- write data to the array
      string symbol  = FileReadString(fileHandle);
      string s_SL    = FileReadString(fileHandle);
      string s_TP    = FileReadString(fileHandle);

      //PrintFormat("SL: %s, TP: %s", s_SL, s_TP);

      double SL = StrToDouble(s_SL);
      double TP = StrToDouble(s_TP);
      if(SL<10 || TP <10)
      {
         Print(__FUNCTION__, " Line ", i, ", SL or TP too SMALL");
         i++;
         continue;
      }
      ArrayResize(_OptimizedTPSL, i+1, 1000);
      _OptimizedTPSL[i].setData(symbol, SL, TP);
      i++;
   }
//--- close the file
   FileClose(fileHandle);
   PrintFormat("Data is read, file %s is closed", fileName);
   return 0;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void getFilteredSignal(CSignal &sourceSignal[], CSignal &desSignal[])
{

   int i=0;
   for(int j=0; j<ArraySize(sourceSignal); j++)
   {
      if(sourceSignal[j].getSymbol() == Symbol())
      {
         ArrayResize(desSignal, i+1, 1000);
         desSignal[i] = sourceSignal[j];
         i++;
      }
   }

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void getOptimizedSLTPofThisSymbol(CSLTP &SLTPRange[])
{
   for(int i=0; i<ArraySize(SLTPRange); i++)
   {
      string temp = SLTPRange[i].getSymbol();
      if(temp == Symbol())
      {
         slPip = SLTPRange[i].getSL();
         tpPip = SLTPRange[i].getTP();
         break;
      }
   }
   return;
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                        LET SET ORDER HERE                        |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void setOrder(CSignal &signal[])
{
   if(ArraySize(signal)==0)
      return;

   for(int i=0; i<ArraySize(signal); i++)
   {
      if(signal[i].getOpenTime() <= Time[0])
      {
         int ticket;
         int type       = signal[i].getType();
         string symbol  = signal[i].getSymbol();

         sendOrder(ticket, symbol, type, lotSize, 0, slPip, tpPip, MAGIC);

         if(ticket<=0)
         {
            Print(__FUNCTION__, " error at Signal Line ", i, ", code:", GetLastError());
            return;
         }

         signal[i].clearData();
      }
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool              sendOrder(int     &_ticket,
                            string  _symbol,
                            int     _type,
                            double  _lot,
                            double  _price,
                            double  _stopLotPip,
                            double  _takeProfitPip,
                            int     _magic,
                            string  _comment="haha")
{
   if(_lot == 0)
   {
      Print("Lot size error (=0)");
      return(false);
   }
   int step = (int) -MathLog10(MarketInfo(_symbol, MODE_LOTSTEP));
   _lot = NormalizeDouble(_lot, step);

   double slPrice=0;
   double tpPrice=0;
   color orderClr=clrNONE;

   if(_type==OP_BUY)
   {
      _price  = MarketInfo(_symbol, MODE_ASK);
      slPrice = _price - _stopLotPip   *10*MarketInfo(_symbol, MODE_POINT);
      tpPrice = _price + _takeProfitPip*10*MarketInfo(_symbol, MODE_POINT);
      orderClr= clrBlue;
   }

   if(_type==OP_SELL)
   {
      _price  = MarketInfo(_symbol, MODE_BID);
      slPrice = _price + _stopLotPip   *10*MarketInfo(_symbol, MODE_POINT);
      tpPrice = _price - _takeProfitPip*10*MarketInfo(_symbol, MODE_POINT);
      orderClr= clrRed;
   }

   _price  = NormalizeDouble(_price, (int) MarketInfo(_symbol, MODE_DIGITS));
   slPrice = NormalizeDouble(slPrice, (int) MarketInfo(_symbol, MODE_DIGITS));
   tpPrice = NormalizeDouble(tpPrice, (int) MarketInfo(_symbol, MODE_DIGITS));

   ResetLastError();
//--- gui lenh
   _ticket = OrderSend(_symbol, _type, _lot, _price, 20, slPrice, tpPrice, _comment, _magic, 0, orderClr);
   if(_ticket <= 0)
   {
      Print("OrderSend() error: ", GetLastError());
      return(false);
   }

// khi đặt lệnh thực tế cần thực hiện chỉnh TP SL, do 1 số sàn k nhận
// 2 tham số này lần đầu đặt lệnh

//--- chinh SL TP
//bool success=false;
//if(_ticket>0 && (slPrice!=0 || tpPrice!=0))
//  {
//   int i=0;
//   while(!success && i<20)
//     {
//      success = OrderModify(_ticket, _price, slPrice, tpPrice, 0, clrNONE);
//      i++;
//      Sleep(50);
//     }
//   if(!success)
//     {
//      Print("Order Modify error: ", GetLastError());
//      return(false);
//     }
//  }

   return(true);

}

//+------------------------------------------------------------------+
