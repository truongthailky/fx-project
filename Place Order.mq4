﻿//+------------------------------------------------------------------+
//|                                                  Place Order.mq4 |
//|                                                 Truong Hong Thai |
//|                                                   truonghongthai |
//+------------------------------------------------------------------+
#property copyright "Truong Hong Thai"
#property link      "truonghongthai"
#property version   "1.00"
#property strict

#include <Telegram.mqh>

string suffix = ".a";
string InpToken="174949****:****VvqYQadX1bY67_0Qc6I5CBgyc7I5zw";
const long owner_id = 1234567;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double slPip = 45; //(pips)
double tpPip = 60; //(pips)
double balance = AccountBalance();
double risk = 1; //(%)
double safeMarginLevel = 200; //%
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string symbolsArray[24] = {"AUDCAD", "AUDCHF", "AUDJPY", "AUDUSD",
                           "EURAUD", "EURCAD", "EURCHF", "EURJPY", "EURNZD", "EURUSD",
                           "GBPAUD", "GBPCAD", "GBPCHF", "GBPJPY", "GBPNZD", "GBPUSD",
                           "NZDCAD", "NZDCHF", "NZDJPY", "NZDUSD",
                           "USDCAD", "USDJPY", "USDCHF", "XAUUSD"
                          }; //24

int totalSymbol = ArraySize(symbolsArray);
string symbolSelect="";
datetime symbolExpire;


string botID="";
long chatID; //Global, dùng lưu dấu config
long msgID; //Global, dùng lưu dấu config

const int magic=1689;

string configTarget;
bool configConfirmed = false;
//+------------------------------------------------------------------+
//|   CMyBot                                                         |
//+------------------------------------------------------------------+
class CMyBot: public CCustomBot
{
private:
   string            m_button[3];
public:
   //+------------------------------------------------------------------+
   void              CMyBot::CMyBot(void)
   {
      m_button[0]="Button #1";
      m_button[1]="Button #2";
      m_button[2]="Button #3";
   }

   //+------------------------------------------------------------------+
   string            GetKeyboard(int index)
   {
      if(index == 0)
      {
         return(StringFormat("[[\"%s\",\"%s\",\"%s\",\"%s\"],"
                             "[\"%s\",\"%s\",\"%s\",\"%s\"],"
                             "[\"%s\",\"%s\",\"%s\",\"%s\"],"
                             "[\"%s\",\"%s\",\"%s\",\"%s\"],"
                             "[\"%s\",\"%s\",\"%s\",\"%s\"],"
                             "[\"%s\",\"%s\",\"%s\",\"%s\"],"
                             "[\"Exit\"]]",
                             "AUDCAD", "AUDCHF", "AUDJPY", "AUDUSD",
                             "EURAUD", "EURCAD", "EURCHF", "EURJPY",
                             "EURNZD", "EURUSD", "GBPAUD", "GBPCAD",
                             "GBPCHF", "GBPJPY", "GBPNZD", "GBPUSD",
                             "NZDCAD", "NZDCHF", "NZDJPY", "NZDUSD",
                             "USDCAD", "USDJPY", "USDCHF", "XAUUSD"));
      }

      if(index == 1)
      {
         return(StringFormat("[[\"BUY\",\"SELL\"],"
                             "[\"Select Symbol\"],"
                             "[\"%sExit%s\"]]",
                             "", ""));
      }

      if(index == 2)   //config thông số tài khoản
      {
         return(StringFormat("[[\"Confirm\"],"
                             "[\"Change config\"],"
                             "[\"%sExit%s\"]]",
                             "", ""));
      }

      if(index == 3)   //config thông số tài khoản
      {
         return(StringFormat("[[\"Confirm\"],"
                             "[\"Change balance\"],"
                             "[\"Change SL\",\"Change TP\",\"Change risk\"],"
                             "[\"%sExit%s\"]]",
                             "", ""));
      }

      return("");

   }

   string            mentionUser(long _fromID, const string _mentionText="!")
   {
      string result = StringFormat("<a href=\"tg://user?id=%d\">%s</a>",
                                   _fromID,
                                   _mentionText);
      return(result);
   }
   //+------------------------------------------------------------------+
   //|                                                                  |
   //+------------------------------------------------------------------+
   bool              claimSmallNumber(long _chatID)
   {
      bot.SendMessage_Confirm(_chatID, "Số bé quá (hoặc to quá) anh zai,"
                              " anh nhập lại đi", msgID, bot.ForceReply());
      chatID=_chatID;

      return(true);
   }

   bool              confirmConfigChange(long _chatID, long _fromID, string _target, double _value)
   {
      string temp = "Đã thay đổi "+_target+" thành ";

      if(_target == "SL" || _target == "SL")
         temp+= DoubleToStr(_value, 0)+"pips";
      else if(_target == "RISK")
         temp+= DoubleToStr(_value, 2)+"%";
      else
         temp+= (string) _value;

      bot.SendMessage(_chatID, temp+mentionUser(_fromID, "!"), bot.ReplyKeyboardMarkup(GetKeyboard(3), false, false), true, false);
      return(true);
   }

   bool              changeConfig(long _chatID, long _fromID, string _text, string &_target)
   {
      _text = StringTrimLeft(_text);
      _text = StringTrimRight(_text);
      double value = StringToDouble(_text);
      Print("value =", value);
      if(_target == "BALANCE")
      {
         if(value<100 || value > 1.5*AccountBalance())
         {
            claimSmallNumber(_chatID);
            return(false);
         }
         else
         {
            balance = value;
            confirmConfigChange(_chatID, _fromID, _target, value);
         }
      }
      else if(_target == "SL")
      {
         if(value<5 || value>200)
         {
            claimSmallNumber(_chatID);
            return(false);
         }
         else
         {
            slPip = value;
            confirmConfigChange(_chatID, _fromID, _target, value);
         }
      }

      else if(_target == "TP")
      {
         if(value<5 || value>200)
         {
            claimSmallNumber(_chatID);
            return(false);
         }
         else
         {
            tpPip = (int) value;
            confirmConfigChange(_chatID, _fromID, _target, value);
         }
      }

      else if(_target == "RISK")
      {
         if(value<0.1 || value>15)
         {
            claimSmallNumber(_chatID);
            return(false);
         }
         else
         {
            risk = NormalizeDouble(value, 2);
            confirmConfigChange(_chatID, _fromID, _target, value);
         }
      }

      _target = "";
      msgID  = 0;
      chatID = 0;

      return(true);
   }
   bool              checkIfTradeIsAllowed(long _chatID, long _fromID)
   {
      if(!configConfirmed)
      {
         bot.SendMessage(_chatID, "Chưa xác nhận thông số tài khoản, vui lòng thiết lập và Confirm", NULL, false, true);
         bot.SendMessage(_chatID, configInfo()+mentionUser(_fromID, "\n_________"), bot.ReplyKeyboardMarkup(GetKeyboard(2), false, false), true, true);
         return(false);
      }
      return(true);
   }
   //+------------------------------------------------------------------+
   void              ProcessMessages(void)
   {
      for(int i=0; i<m_chats.Total(); i++)
      {
         CCustomChat *chat=m_chats.GetNodeAtIndex(i);
         if(!chat.m_new_one.done)
         {
            chat.m_new_one.done=true;
            string text  =chat.m_new_one.message_text;
            long   fromID=chat.m_new_one.from_id;
            long   replyToChatID=chat.m_reply_to_msid;
            string fromName=chat.m_new_one.from_first_name+" "+chat.m_new_one.from_last_name;

            Print("Chat ID: ", chat.m_id, ", FromID: ", fromID);
            Print(text);

            //--- kiểm duyệt xem có đúng địa chỉ người gửi không
            if(fromID!=owner_id)
            {
               bot.SendMessage(chat.m_id, fromName+", bạn chưa được cấp quyền đặt lệnh, liên hệ Trương Hồng Thái");
               return;
            }

            //--- set upper and lower text
            string textUpper = text, textLower = text;
            StringToUpper(textUpper);
            StringToLower(textLower);

            //--- help commands
            if(text=="/help" ||
                  text=="/help@"+botID)
            {
               bot.SendMessage(chat.m_id, instruction()+mentionUser(fromID), bot.ReplyKeyboardHide(), true, true);
               return;
            }

            //--- start and config
            if(text=="/start" ||
                  text=="/config"||
                  text=="/start@"+botID ||
                  text=="/config@"+botID)
            {
               bot.SendMessage(chat.m_id, fromName+", vui lòng xác nhận thông tin giao dịch dưới đây!", NULL, false, true);
               bot.SendMessage(chat.m_id, configInfo()+mentionUser(fromID, "\n_________"), bot.ReplyKeyboardMarkup(GetKeyboard(2), false, false), true, true);
               return;
            }

            //--- change config
            if(textLower=="change config")
            {
               bot.SendMessage(chat.m_id, "Lựa chọn thay đổi thông số "+mentionUser(fromID, "\nThanks!"),
                               bot.ReplyKeyboardMarkup(GetKeyboard(3), false, false), true, true);
               return;
            }

            //--- gửi yêu cầu nhập value cho config cần thay đổi
            if(textLower=="change balance" ||
                  textLower=="change sl" ||
                  textLower=="change tp" ||
                  textLower=="change risk")
            {
               string target=StringSubstr(textUpper, 7);
               configTarget=target;

               if(target=="SL" || target=="TP")
                  target+="(pips)";
               else if(target=="RISK")
                  target+="(%)";

               string temp="Thay đổi "+target+" bằng cách trả lời tin nhắn này ở dạng số";

               chatID=chat.m_id;
               bot.SendMessage_Confirm(chat.m_id, temp, msgID, bot.ForceReply(), false, true);
               return;
            }

            //--- thay đổi config
            if(replyToChatID != 0 &&
                  replyToChatID == msgID &&
                  chat.m_id     == chatID &&
                  configTarget  != "")
            {
               changeConfig(chat.m_id, fromID, text, configTarget);
               return;
            }

            //--- xác nhận config và cho phép giao dịch
            if(textLower=="confirm")
            {
               configConfirmed=true;
               string temp = StringConcatenate("Thông tin giao dịch\n/*-------------------*/\n",
                                               configInfo(),
                                               "\n/*-------------------*/\n",
                                               "Đã được xác nhận. Chúc ", fromName, " trade thắng lớn");
               bot.SendMessage(chat.m_id, temp+mentionUser(fromID), bot.ReplyKeyboardMarkup(GetKeyboard(0), false, false), true, true);
               return;
            }

            //--- select symbol
            if(text=="Select Symbol")
            {
               if(!checkIfTradeIsAllowed(chat.m_id, fromID))
                  return;
               bot.SendMessage(chat.m_id, "Chọn cặp tiền "+mentionUser(fromID, "\xF4B5\xF4B6"), bot.ReplyKeyboardMarkup(GetKeyboard(0), false, false), true, true);
               return;
            }

            //--- confirm cặp tiền, yêu cầu nhập loại lệnh
            for(int k=0; k<totalSymbol; k++)
            {
               if(textUpper==symbolsArray[k])
               {
                  if(!checkIfTradeIsAllowed(chat.m_id, fromID))
                     return;
                  symbolSelect=textUpper;
                  symbolExpire = TimeCurrent() + 15;
                  bot.SendMessage(chat.m_id, "Chọn loại lệnh BUY/SELL"+mentionUser(fromID), bot.ReplyKeyboardMarkup(GetKeyboard(1), false, false), true, true);
                  return;
               }
            }

            //--- đặt lệnh BUY/SELL
            if(textLower=="buy" || textLower=="sell")
            {
               if(!checkIfTradeIsAllowed(chat.m_id, fromID))
                  return;
               if(symbolSelect =="")
               {
                  bot.SendMessage(chat.m_id, "Chưa chọn cặp tiền (thông tin về cặp tiền đã chọn sẽ tự động reset sau 15 giây)"+mentionUser(fromID),
                                  bot.ReplyKeyboardMarkup(GetKeyboard(0), false, false), true, true);
                  return;
               }
               else
               {
                  if(!checkIfTradeIsAllowed(chat.m_id, fromID))
                     return;
                  string temp = sendOrder_Super(symbolSelect, textLower);
                  bot.SendMessage(chat.m_id, temp, NULL, false, true);
                  return;
               }
            }

            //--- đặt lệnh nhanh
            string quick[];
            while(StringReplace(textUpper, "  ", " "));
            StringSplit(textUpper, ' ', quick);
            if(ArraySize(quick)==2 && (quick[0]=="BUY" || quick[0]=="SELL"))
            {
               for(int k=0; k<ArraySize(symbolsArray); k++)
               {
                  if(quick[1] == symbolsArray[k])
                  {
                     Print("Fire in the hole");
                     if(!checkIfTradeIsAllowed(chat.m_id, fromID))
                        return;
                     string temp = sendOrder_Super(quick[1], quick[0]);
                     bot.SendMessage(chat.m_id, temp, NULL, false, true);
                     return;
                  }
               }
               bot.SendMessage(chat.m_id, "Lỗi: sai định dạng cặp tiền, hoặc cặp tiền chưa được hỗ trợ đặt lệnh", NULL, false, true);
               return;

            }

            //--- exit and hide keyboard
            if(textLower=="exit")
            {
               bot.SendMessage(chat.m_id, "Bye bye, call me if needed /help "+mentionUser(fromID, "\xF3C4"), bot.ReplyKeyboardHide(), true, true);
               return;
            }

            bot.SendMessage(chat.m_id, "Câu lệnh chưa được hỗ trợ hoặc sai cú pháp /help");
            return;

         }
      }
   }
};





CMyBot            bot;
int               getme_result;
//+------------------------------------------------------------------+
//|   OnInit                                                         |
//+------------------------------------------------------------------+
int               OnInit()
{
//--- set token
   bot.Token(InpToken);
//--- check token
   getme_result=bot.GetMe();
//--- show bot name
   Comment("Bot name: ", bot.Name());
   botID = bot.Name();
//--- run timer
   EventSetMillisecondTimer(500);
   OnTimer();
//--- done
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void              OnDeinit(const int reason)
{
//--- destroy timer
   EventKillTimer();

}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void              OnTimer()
{
//--- show error message end exit
   if(getme_result!=0)
   {
      Comment("Error on getme_result: ", GetErrorDescription(getme_result));
      return;
   }
//--- show bot name
   Comment("Bot name: ", bot.Name());
//--- check expiry of symbol select
   if(TimeCurrent() > symbolExpire)
      symbolSelect="";
//--- reading messages
   bot.GetUpdates();
//--- processing messages
   bot.ProcessMessages();

}
//+------------------------------------------------------------------+
int               countOrdered(string _symbol)
{
   int dem = 0;

   for(int i = OrdersTotal() - 1; i >= 0 ; i++)
   {
      if(OrderSelect(i, SELECT_BY_POS)==False)
         continue;

      if(OrderSymbol() != _symbol)
         continue;

      if(OrderMagicNumber() != magic)
         continue;

      dem ++;
   }
   return(dem);

}



//+------------------------------------------------------------------+
bool              sendOrder(int &_ticket, string _symbol, int _type, double _lot, double _price, double _stopLotPip, double _takeProfitPip, int _magic, string _comment="")
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
   _ticket = OrderSend(_symbol, _type, _lot, _price, 20, 0, 0, _comment, _magic, 0, orderClr);
   if(_ticket <= 0)
   {
      Print("OrderSend() error: ", GetLastError());
      return(false);
   }
//--- chinh SL TP
   bool success=false;
   if(_ticket>0 && (slPrice!=0 || tpPrice!=0))
   {
      int i=0;
      while(!success && i<20)
      {
         success = OrderModify(_ticket, _price, slPrice, tpPrice, 0, clrNONE);
         i++;
         Sleep(50);
      }
      if(!success)
      {
         Print("Order Modify error: ", GetLastError());
         return(false);
      }
   }

   return(true);

}
//+------------------------------------------------------------------+
double            cal_LotFromPip(string _symbol, double _balance, double _risk=1, const double _stopLossPip=30)
{
   double tradeVolume;
   double riskMoney = _balance*_risk/100;
   double tickValue = MarketInfo(_symbol, MODE_TICKVALUE);

//--- buộc update tickValue
   if(tickValue == 0)
   {
      uint timer = GetTickCount();
      long chartID = ChartOpen(_symbol, PERIOD_M1);

      do
      {
         Sleep(50);
         RefreshRates();
         ChartRedraw(chartID);
         tickValue = MarketInfo(_symbol, MODE_TICKVALUE);
      }
      while(tickValue == 0 && GetTickCount() - timer < 1000);
      ChartClose(chartID);
   }

//--- CÔNG THỨC CHÍNH
   if(_stopLossPip!=0 && tickValue !=0)
   {
      tradeVolume = riskMoney/(_stopLossPip*10*tickValue);
   }
   else
   {
      Print("Error when calculate tradeVolume - main function");
      return(-1);
   }

//---
   if(tradeVolume==0)
   {
      tradeVolume = MarketInfo(_symbol, MODE_MINLOT);
   }
   if(tradeVolume > MarketInfo(_symbol, MODE_MAXLOT))
   {
      tradeVolume = MarketInfo(_symbol, MODE_MAXLOT);
   }
   double lotStep = MarketInfo(_symbol, MODE_LOTSTEP);
   int    step    = (int) -MathLog10(lotStep);
   tradeVolume    = NormalizeDouble(tradeVolume, step);

   return(tradeVolume);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool              symbolModify(string &symbol)
{
   symbol += suffix;
   return(true);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
string            instruction()
{
   string temp;
   temp = StringConcatenate("/start hoặc /config để bắt đầu cấu hình đặt lệnh",
                            "\n\n!!!Cần cấu hình đầy đủ trước khi đặt lệnh!!!\n",
                            "\n/info để xem thông tin về tài khoản",
                            "\n/summary để xem tóm tắt về tình trạng giao dịch",
                            "\nĐặt lệnh bằng cách tương tác với bàn phím ảo",
                            "\n\n**Hoặc có thể đặt lệnh nhanh theo cú pháp \'SELL EURUSD\'",
                            "\n\n(Nếu ở trong group, bạn phải reply bot thì bot mới đọc được tin nhắn! ",
                            "còn inbox trực tiếp cho bot thì vô tư)");
   return(temp);

}
//+------------------------------------------------------------------+
string            configInfo()
{
   string temp;
   temp = StringConcatenate(AccountServer(),                   "\n"
                            "Account Name: ", AccountName(),   "\n",
                            "Account Num: ", AccountNumber(),  "\n",
                            "Balance: ", AccountCurrency()=="USD"?"$":AccountCurrency()+" ",
                            DoubleToStr(AccountBalance(), 2),   "\n",
                            "Leverage: 1:", AccountLeverage(),  "\n",
                            "TP: ", tpPip, "pips",               "\n",
                            "SL: ", slPip, "pips",               "\n",
                            "Risk: ", DoubleToStr(risk, 2), "%"
                           );

   return(temp);
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
string sendOrder_Super(string _symbol, string _strtype = "BUY")
{
   symbolModify(_symbol); //Thêm hậu tố cho cặp tiền, nếu không sẽ không giao dịch được

//---
   StringToUpper(_strtype);
   int type;
   if(_strtype=="BUY")
      type=OP_BUY;
   else if(_strtype=="SELL")
      type=OP_SELL;
   else
      return("Không hỗ trợ loại lệnh này");

   ResetLastError();
//---
   double volume = cal_LotFromPip(_symbol, balance, risk, slPip);
   if(volume==-1)
      return("Lỗi khi tính toán Lot Size (có thể do mạng chậm, chưa lấy được TickValue)");

   Print("Check free margin: ", AccountFreeMarginCheck(Symbol(), OP_BUY, volume));
   if(GetLastError()==134)
      return("Not enough money");

   if(AccountInfoDouble(ACCOUNT_MARGIN_LEVEL) < safeMarginLevel)
      return("Margin level nhỏ hơn "+(string)safeMarginLevel+"%, không nên đặt lệnh nữa anh zai");      

//--- hàm đặt lệnh chính
   int ticket;
   bool result = sendOrder(ticket, _symbol, type, volume, 0, slPip, tpPip, magic);

   if(ticket<=0)
      return("Lỗi: không thể đặt lệnh. Error code: "+(string)GetLastError());

   Print("Ticket: ", ticket);

   if(!OrderSelect(ticket, SELECT_BY_TICKET))
      return("Ticket: "+(string)ticket+"\nOrder thành công, tuy nhiên không thể lấy thông tin. Error code: "+(string)GetLastError());

   double newTP=0, newSL=0;
   if(OrderType() == OP_BUY)
   {
      newTP = (-OrderOpenPrice() + OrderTakeProfit())/SymbolInfoDouble(_symbol, SYMBOL_POINT)/10;
      newSL = (+OrderOpenPrice() - OrderStopLoss())/SymbolInfoDouble(_symbol, SYMBOL_POINT)/10;
   }
   else if(OrderType() == OP_SELL)
   {
      newTP = (+OrderOpenPrice() - OrderTakeProfit())/SymbolInfoDouble(_symbol, SYMBOL_POINT)/10;
      newSL = (-OrderOpenPrice() + OrderStopLoss())/SymbolInfoDouble(_symbol, SYMBOL_POINT)/10;
   }

   string strNewTP = DoubleToString(newTP, 0);
   string strNewSL = DoubleToString(newSL, 0);

   string notify = StringConcatenate(OrderOpenTime(),
                                     "\nOrder: ", OrderTicket(),
                                     "\nSymbol: ", _symbol,
                                     "\nType: ", _strtype,
                                     "\nLot size: ", OrderLots(),
                                     "\nEntry: ", OrderOpenPrice(),
                                     "\nTake Profit: ", OrderTakeProfit(), " (", strNewTP, "pips)",
                                     "\nStop Loss: ", OrderStopLoss(), " (", strNewSL, "pips)"
                                    );

   if(!result)
   {
      notify += "\nLỗi không thể đặt TP SL";
      return(notify);
   }
   else
      notify+="\n__SUCCESS__";

   return(notify);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
string getOrderInfo(const int _ticket)
{
   double newSL=0, newTP=0;
   string symbol = OrderSymbol();
   string strType;
   string notify;

   if(!OrderSelect(_ticket, SELECT_BY_TICKET, MODE_TRADES|MODE_HISTORY))
      return("Không tìm thấy Order, kiểm tra lại ticker number");

   int symbolDigit = -(int)MathLog10(SymbolInfoDouble(symbol, SYMBOL_POINT));
   double symbolPoint = SymbolInfoDouble(symbol, SYMBOL_POINT);
//--- tính lại SL, TP sau khi đặt lệnh
   if(OrderType() == OP_BUY)
   {
      strType = "BUY";
      newTP = (-OrderOpenPrice() + OrderTakeProfit())/symbolPoint/10;
      newSL = (+OrderOpenPrice() - OrderStopLoss()  )/symbolPoint/10;
   }
   else if(OrderType() == OP_SELL)
   {
      strType = "SELL";
      newTP = (+OrderOpenPrice() - OrderTakeProfit())/symbolPoint/10;
      newSL = (-OrderOpenPrice() + OrderStopLoss()  )/symbolPoint/10;
   }

   newTP = NormalizeDouble(newTP, 0);
   newSL = NormalizeDouble(newSL, 0);

   notify = StringFormat("Open: %s"
                         "\n%s %s %s(lots)"
                         "\nPrice: %s"
                         "\nTP: %s (%s pips)"
                         "\nSL: %s (%s pips)",
                         (string)OrderOpenTime(),
                         strType, symbol, (string)OrderLots(),
                         DoubleToStr(OrderOpenPrice(), symbolDigit),
                         (string)OrderTakeProfit(), (string) newTP,
                         (string)OrderStopLoss(), (string) newSL
                        );

   string strNetProfit = DoubleToStr(OrderProfit()+OrderCommission()+OrderSwap(), 2);

//--- kiểm tra xem lệnh đã đóng chưa
   if(OrderCloseTime()==0)
   {
      notify += "\n__PENDING__";
      notify += "\nCurrent net profit: $"+strNetProfit;
   }
   else
   {
      notify+= "\n------------------";
      notify+= "\nCLOSED at"+(string)OrderCloseTime();
      notify+= "Close price: "+(string)OrderClosePrice();
      notify+= "Net profit: $"+strNetProfit;
   }

   return notify;
}
//+------------------------------------------------------------------+
