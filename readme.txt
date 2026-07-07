Question:
1. what would happen if the device has no internet? Would it send all the data when the internet is back?
   Answer: Yes. Keystroke data stays on disk (keypress_logs.txt) and keeps accumulating until
   it is successfully sent. The file is only cleared after a successful HTTP 200 response from
   Telegram. The periodic task retries every 5 minutes, so when internet comes back the file
   will be sent automatically on the next cycle.
   For Calls & SMS: the data is always safe in the phone's own call log / message inbox.
   On the next successful cycle, a fresh snapshot (last 30 calls, last 50 SMS) is sent.

2. Before sending data, the app is check if there is internet? what if the user turns off wifi and mobile data both? 
   Answer: No explicit internet check is done. The app simply attempts the HTTP request.
   If there is no internet, the connection throws an exception which is caught silently.
   The log file is NOT cleared on failure, so no data is lost. The next 5-minute cycle
   will try again automatically.

3. If the internet is not working or user turns off mobile data/wifi, in this case, will the be cached and when internet is working or turn on wifi/mobile data, will it try to send again?
   Answer: Yes — keystroke data is cached on disk automatically (this is how the file-based
   approach works). The retry is handled by the 5-minute periodic task. No extra code is needed.
   Summary:
     - Keystrokes  → cached on disk, auto-sent at next 5-min cycle when internet is back.
     - Calls / SMS → always in the phone log, a fresh snapshot is sent on next successful cycle.


Plan: 
1. send all data to email also
2.add firebase to register email.
3. show the data after authentication: invisible slider > password
4. password will be the email
