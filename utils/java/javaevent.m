classdef (ConstructOnLoad) javaevent < event.EventData
   properties
      java
      data
   end
   
   methods
      function obj = javaevent(evt,data)
         obj.java = evt;
         if nargin >= 2
             obj.data = data;
         end
      end
   end
end