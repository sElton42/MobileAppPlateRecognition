function iou = calcIou(yi,yf,xi,xf,o_yi,o_yf,o_xi,o_xf)
%% FUNCAO PARA REALIZAR O CALCULO DO IOU

xA = max(xi, o_xi);
yA = max(yi, o_yi);
xB = min(xf, o_xf);
yB = min(yf, o_yf);

interArea = (xB - xA + 1) * (yB - yA + 1);

boxAArea = (xf - xi + 1) * (yf - yi + 1);
boxBArea = (o_xf - o_xi + 1) * (o_yf - o_yi + 1);

iou = interArea / (boxAArea + boxBArea - interArea);

end