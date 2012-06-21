#include <stderror.mqh>
#include <stdlib.mqh>

#define WAIT_TIME 5

extern double  lots=0.04;
extern double  stopWidth=0.9;
extern double  slippage=3;

color MarkColor[6] = {Red, Blue, Red, Blue, Red, Blue};

int start() {
   if (IsTradeAllowed() == false) {
      Print("Trade is not Allowed.");
      return(0);
   }
   process();
   return(0);
}

void process() {
   int errCode;
   double askPrice = Ask;
   int ticket = doOrderSend(OP_BUY, lots, askPrice, slippage, 0, 0, "", 0, errCode);
   if (ticket != -1) {
      OrderSelect(ticket, SELECT_BY_TICKET);
      OrderModify(ticket, OrderOpenPrice(), OrderOpenPrice() - stopWidth, 0, Red);
   }

}

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