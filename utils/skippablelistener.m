function el = skippablelistener(h,eventName,fcn)

s = skippablecallback(fcn);
el = event.listener(h,eventName,@s.trigger);
el.Recursive = true;

end

