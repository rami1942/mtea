#include <stderror.mqh>
#include <stdlib.mqh>

extern double  lots=0.04;
extern double  slippage=3;

color MarkColor[6] = {DarkViolet, DarkViolet, DarkViolet, DarkViolet, DarkViolet
, DarkViolet};

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
   double bidPrice = Bid;
   int ticket = doOrderSend(OP_SELL, lots, bidPrice, slippage, 0, 0, "", 0, errCode);
   if (ticket != -1) {
      OrderSelect(ticket, SELECT_BY_TICKET);
      OrderModify(ticket, OrderOpenPrice(), 0, 0, Blue);
   }

}

int doOrderSend(int type, double lots, double openPrice, int slippage, double st
oploss, double closePrice, string comment, int magic, int &errCode) {
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
