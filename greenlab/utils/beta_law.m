function y = beta_law(x,a,b,c,T)
if x < -c || (x+c) > T 
    y = 0;
else 
    N = ((a-1)/(a+b-2))^(a-1)*((b-1)/(a+b-2))^(b-1);
    y = ((x+c)/T)^(a-1)*(1-(x+c)/T)^(b-1);
    y = 1/N*y;
end
end