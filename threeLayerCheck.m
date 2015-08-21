function[ x ] = threeLayerCheck( L )

l1 = L(1);
l2 = L(2);
l3 = L(3);

filename = strcat(int2str(L(1)),'-',int2str(L(2)),'-',int2str(L(3)),'.txt');


fileID = fopen(filename,'w');
formatSpecHeader = 'The layout is %1.0f - %1.0f - %1.0f.\n';
fprintf(fileID,formatSpecHeader,L(1),L(2),L(3));

[ x, opt, nonopt, totalruns, skipped ] = checkallwirings(L);

formatSpec = 'The percentage of optimal wirings is %3.4f.\n';
fprintf(fileID,formatSpec,x);
fprintf(fileID,'Total %hd \n', totalruns);
fprintf(fileID,'Skipped %hd \n', skipped);
fprintf(fileID,'Optimal: %hd \n',opt);
fprintf(fileID,'Nonoptimal: %hd \n',nonopt);
fclose(fileID);

end