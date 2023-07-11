//+------------------------------------------------------------------+
//|                                                   MACDCustom.mq4 |
//|                               Copyright 2012-2020, Orchard Forex |
//|                                     https://www.orchardforex.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012-2020, Novateq Pty Ltd"
#property link "https://www.orchardforex.com"
#property version "1.00"

//	MACD indicator inputs
input int    InpFastEmaPeriod   = 12; //	Fast EMA Period
input int    InpSlowEmaPeriod   = 26; //	Slow EMA Period
input int    InpSignalSmaPeriod = 9;  //	Signal SMA Period

input int    InpTakeProfitPts   = 100; //	Take profit points
input int    InpStopLossPts     = 100; //	Stop loss points

input double InpOrderSize       = 0.01;     //	Order size
input string InpTradeComment    = __FILE__; //	Trade comment
input int    InpMagicNumber     = 2000001;  //	Magic number

double       TakeProfit; //	After conversion from points
double       StopLoss;

//
//	Identify the buffer numbers
//
const string IndicatorName = "MACD";
const int    BufferMACD    = 0;
const int    BufferSignal  = 1;

int          OnInit() {

   double point = SymbolInfoDouble( Symbol(), SYMBOL_POINT );
   TakeProfit   = InpTakeProfitPts * point;
   StopLoss     = InpStopLossPts * point;

   return ( INIT_SUCCEEDED );
}

void OnDeinit( const int reason ) {}

void OnTick() {

   //
   //	Where this is to only run once per bar
   //
   if ( !NewBar() ) return;

   //
   //	Perform any calculations and analysis here
   //
   static double lastMACD      = 0;
   static double lastSignal    = 0;
   double        currentMACD   = iCustom( Symbol(), Period(), IndicatorName, InpFastEmaPeriod, InpSlowEmaPeriod, InpSignalSmaPeriod, BufferMACD, 1 );
   double        currentSignal = iCustom( Symbol(), Period(), IndicatorName, InpFastEmaPeriod, InpSlowEmaPeriod, InpSignalSmaPeriod, BufferSignal, 1 );
   //
   //	Execute the strategy here
   //
   //	Buy if MACD is negative
   //		and MACD from bar 2 is below signal
   //		and MACD from bar 1 (just closed) is above signal
   //		( MACD has just crossed up)
   //	Sell if MACD is positive
   //		and MACD from bar 2 is above signal
   //		and MACD from bar 1 (just closed) is below signal
   //		( MACD has just crossed down)
   bool          buyCondition  = ( lastMACD < 0 && lastMACD <= lastSignal ) //	Last bar signal below MACD
                       && ( currentMACD > currentSignal );                  //	MACD has crossed
   bool sellCondition = ( lastMACD > 0 && lastMACD >= lastSignal )          //	Last bar signal above MACD
                        && ( currentMACD < currentSignal );                 //	MACD has crossed

   if ( buyCondition ) {
      OrderOpen( ORDER_TYPE_BUY, StopLoss, TakeProfit );
   }
   else if ( sellCondition ) {
      OrderOpen( ORDER_TYPE_SELL, StopLoss, TakeProfit );
   }

   //
   //	Save any information for next time
   //
   lastMACD   = currentMACD;
   lastSignal = currentSignal;

   return;
}

//+------------------------------------------------------------------+

bool NewBar() {

   static datetime prevTime    = 0;
   datetime        currentTime = iTime( Symbol(), Period(), 0 );
   if ( currentTime != prevTime ) {
      prevTime = currentTime;
      return ( true );
   }
   return ( false );
}

bool OrderOpen( ENUM_ORDER_TYPE orderType, double stopLoss, double takeProfit ) {

   int    ticket;
   double openPrice;
   double stopLossPrice;
   double takeProfitPrice;

   if ( orderType == ORDER_TYPE_BUY ) {
      openPrice       = SymbolInfoDouble( Symbol(), SYMBOL_ASK );
      stopLossPrice   = openPrice - stopLoss;
      takeProfitPrice = openPrice + takeProfit;
   }
   else if ( orderType == ORDER_TYPE_SELL ) {
      openPrice       = SymbolInfoDouble( Symbol(), SYMBOL_BID );
      stopLossPrice   = openPrice + stopLoss;
      takeProfitPrice = openPrice - takeProfit;
   }
   else {
      return ( false );
   }

   ticket = OrderSend( Symbol(), orderType, InpOrderSize, openPrice, 0, stopLossPrice, takeProfitPrice, InpTradeComment, InpMagicNumber );

   //	Check return codes here

   return ( ticket > 0 );
}
