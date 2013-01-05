//+------------------------------------------------------------------+
//|                                            ManagedTrapRepeat.mq4 |
//|                                                         rami1942 |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright "rami1942"
#property link      ""

#include <stderror.mqh>
#include <stdlib.mqh>

#define WAIT_TIME 5
#define COMMENT "ManagedTrapRepeat"

#import "fxc.dll"
   int InitEnv();
   int TerminateEnv();
   int Connect();
   int Disconnect();
   int GetTrapList(double buffer[]);
   int UpdatePrice(double price);
   int GetTrapLots();
   double GetTakeProfitWidth();
   int GetDeleteRequest(double prices[]);
   int SetMark();
   int ClearMark();
   int UpdatePosition(int, int, int, double, double, double, int, double, double, string);
   int SetAccountInfo(double, double);
   int GetHistoryRequest(int ticketNo[], int posCd[]);
   int InsertHistory(int, int, int, int, string, double, string, double, double, double, string, double, double, double);
#import

//--- input parameters
extern int       slippage=1;
extern double    lowlimitRate = 0;
extern double    highlimitRate = 0;
extern bool      stopOnly = false;
extern bool      isBuy = false;

color MarkColor[6] = {Red, Blue, Red, Blue, Red, Blue};

int poolMagics[];
int poolTickets[];

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init() {
   if (!InitEnv()) {
      Print("Initialize ODBC failed.");
      return(0);
   }

   return(0);
}
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit() {
   TerminateEnv();
   return(0);
}

//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start() {
   if (IsTradeAllowed() == false) {
      Print("Trade is not Allowed.");
      return(0);
   }
   initPool();
   if (Connect() == 1) {
      doEachTick();
      Disconnect();
   }
   
   return(0);
}


//+------------------------------------------------------------------+

// Run every tick.
void doEachTick() {

   double lots = GetTrapLots() / 100000.0;
   if (lots == 0) {
      Print("GetTrapLots failed.");
      return (0);
   }
   
   double targetPips = GetTakeProfitWidth();
   if (targetPips == 0) {
      Print("GetTakeProfitWidth failed.");
      return(0);
   }
   
   
   double buffer[64];
   if (!GetTrapList(buffer)) {
      Print("GetTrapList failed.");
   } else {
      int i = 0;
      while(true) {
         if (buffer[i] == 0.0) break;
         int tgtMagic = 100000 + buffer[i] * 100;
         if (!isPositionOrdered(tgtMagic)) {
            processOrder(buffer[i], lots, tgtMagic, targetPips, isBuy);
         }
         i++;
      }
   }
   
   UpdatePrice(Bid);
   deleteShort();
   
   SetAccountInfo(AccountBalance(), AccountMargin());
   
   if (SetMark() == 1) {
      for (i = 0; i < OrdersTotal(); i++) {
         if (!OrderSelect(i, SELECT_BY_POS)) continue;
         if (OrderType() != OP_BUY && OrderType() != OP_SELL) continue;
         UpdatePosition(OrderTicket(), OrderMagicNumber(), OrderType(),
                           OrderOpenPrice(), OrderTakeProfit(), OrderStopLoss(), OrderSwap(), OrderProfit(),
                           OrderLots(), OrderSymbol());
         
      }   
      ClearMark();
   }
   
   processHistory();
}

void deleteShort() {
   double prices[];
   int n = OrdersTotal();
   ArrayResize(prices, n + 1);

   if (!GetDeleteRequest(prices)) {
      Print("GetDeleteRequest failed.");
      return;
   }
   
   int i = 0;
   while(true) {
      if (prices[i] == 0.0) break;
      
      int magic = 100000 + prices[i] * 100;
      int ticket = getTicket(magic);
      
      if (ticket == -1) continue;
      if (!OrderSelect(ticket, SELECT_BY_TICKET)) continue;
      if (OrderType() == OP_SELL || OrderSymbol() != Symbol()) continue;
      
      OrderDelete(ticket);
      
      i++;
   }
}

void processOrder(double targetPrice, double lots, int magic, double targetPips, bool isBuy) {   
   int errCode;
   
   if (isBuy) {
      if (Ask <= targetPrice) {
         doOrderSend(OP_BUYSTOP, lots, targetPrice, slippage, lowlimitRate, targetPrice + targetPips, COMMENT, magic, errCode);
      } else {
         if (!stopOnly) {
            doOrderSend(OP_BUYLIMIT, lots, targetPrice, slippage, lowlimitRate, targetPrice + targetPips, COMMENT, magic, errCode);
         }
      }
   } else {
      if (Bid <= targetPrice) {
         if (!stopOnly) {
            doOrderSend(OP_SELLLIMIT, lots, targetPrice, slippage, highlimitRate, targetPrice - targetPips, COMMENT, magic, errCode);
         }
      } else {
         doOrderSend(OP_SELLSTOP, lots, targetPrice, slippage, highlimitRate, targetPrice - targetPips, COMMENT, magic, errCode);
      }
   }
}

// Is the position is ordered?
bool isPositionOrdered(int magic) {
   int ticket = getTicket(magic);   
   return (ticket != -1);
}

// Send a order.
//
// returns ticket no or -1 if failed.
int doOrderSend(int type, double lots, double openPrice, int slippage, double stoploss, double closePrice, string comment, int magic, int &errCode) {
   openPrice = NormalizeDouble(openPrice, Digits);
   stoploss = NormalizeDouble(stoploss, Digits);
   closePrice = NormalizeDouble(closePrice, Digits);

   int starttime = GetTickCount();

   while(true) {
      if(GetTickCount() - starttime > WAIT_TIME * 1000) {
         Print("OrderSend timeout. Check the experts log.");
         return(false);
      }

      if(IsTradeAllowed() == true) {
         RefreshRates();
         int ticket = OrderSend(Symbol(), type, lots, openPrice, slippage, stoploss, closePrice, comment, magic, 0, MarkColor[type]);
         if( ticket > 0) {
            return(ticket);
         }

         errCode = GetLastError();
         Print("[OrderSendError] : ", errCode, " ", ErrorDescription(errCode));
         Print("price=",openPrice,": stop=",stoploss,": close=",closePrice);
         if(errCode == ERR_INVALID_PRICE || errCode == ERR_INVALID_STOPS) {
            return(-1);
         }
      }
      Sleep(100);
   }
}

// Initialize poolMagics and poolTickets.
void initPool() {
   int n = 0;
   for (int i = 0; i < OrdersTotal(); i++) {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if (OrderSymbol() != Symbol()) continue;
      n++;
   }
   
   ArrayResize(poolMagics, n);
   ArrayResize(poolTickets, n);
   
   n = 0;
   for (i = 0; i < OrdersTotal(); i++) {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if (OrderSymbol() != Symbol()) continue;
      
      poolTickets[n] = OrderTicket();
      poolMagics[n] = OrderMagicNumber();
      
      n++;
   }
}

// Retrieve magic no to ticket no.
int getTicket(int magic) {
   for (int i = 0; i < ArraySize(poolMagics); i++) {
      if (poolMagics[i] == magic) return(poolTickets[i]);
   }
   return(-1);
}

void processHistory() {

   int tickets[128], pos[128];
   
   if (GetHistoryRequest(tickets, pos) == 1) {
      int i = 0;
      while(true) {
         if (tickets[i] == 0) break;
         
         if (!OrderSelect(tickets[i], SELECT_BY_TICKET)) {
            Print("ticket no ", tickets[i], " is not exist.");
            i++;
            continue;
         }
         
         int magicNo = OrderMagicNumber();
         string openDt = TimeToStr(OrderOpenTime());
         double lots = OrderLots();
         string symbol = OrderSymbol();
         
         double openPrice = OrderOpenPrice();
         double slPrice = OrderStopLoss();
         double tpPrice = OrderTakeProfit();
         
         string closeDt = TimeToStr(OrderCloseTime());
         double closePrice = OrderClosePrice();
         
         double swapPoint = OrderSwap();
         double profit = OrderProfit();
         
         InsertHistory(tickets[i], magicNo, OrderType(), pos[i], openDt, lots, symbol, 
            openPrice, slPrice, tpPrice, closeDt, closePrice, swapPoint, profit);
         
         i++;
      }
   }

}

