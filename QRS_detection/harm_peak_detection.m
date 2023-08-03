function [peak_list] = harm_peak_detection(ecg,freq)
    % function [peak_list] = PeakDetection(ecg,freq )
    %
    % input:
    % ecg : ecg wave form, row vector
    % freq: sampling frequency
    %
    % output:
    % peak_list: row vector, where the entries are the positions in the vector
    % 'ecg' that correspond to the peaks (divide by 'freq' to get the times of
    % the peaks in seconds
    %
    ecg = ecg';
    
    x=0; % x is the coordinate if the last peak

    n=length(ecg);
    ecg=conv(ecg,ones(1,round(freq*.02)),'same');
    f=PeakFilter(ecg,freq); % apply the special filter that enhances peaks
    peak_list=[];

    t=[1:4*freq]/freq; 
    shape=t.^2./(1+100*(t-.2).^4); % shape is the anticipation curve
    % the value of f is scaled according to the last peak that appeared using
    % the anticipation curve (for example, the next peak is more likely to come
    % after .8s than after .2s.
    ls=length(shape);

    while x+.25*freq<n
        m=min(ls,n-x);
        [u,y]=max(shape(1:m).*f(x+1:x+m)); % scale f with shape, then find max
        x=x+y; % move x to the next peak

         if m==ls
            peak_list=[peak_list,x]; % add newly found peak to the list
         else
             if shape(y)*f(x)>shape(n-x+y)*(.3)
                 peak_list=[peak_list,x]; % something ad-hoc for peak at the very end
             end
         end

    end
    
%     plot(ecg);
%     hold on;
%     scatter(peak_list,ecg(peak_list));
%     hold off;
    % make a nice picture, but one can comment this out if not wanted
    
    peak_list = peak_list';    
end


function [peak_signal_score] = PeakFilter(ecg,freq)
    % function [peak_signal] =PeakFilter(ecg,freq)
    % takes an ecg and converts it to a signal
    % that enhances the R-peaks
    %
    % input:
    % ecg: ecg wave form, row vector
    % freq: sampling frequency
    %
    % output
    % peak_signal: filtered signal

    % parameters that can be adjusted:
    peak_width=.035; 
    % width of (part of) QRS-complex is roughly 2*.035=.7s
    % used to differentiate between QRS complex and T/P waves.

    window_width=1; 
    % width of window used for smoothing (in sec)

    [m,n]=size(ecg);
    ww=floor(window_width*freq);
    window=ones(1,ww);
    u=ones(1,n);
    pw=floor(peak_width*freq);
    peak_signal=sqrt(max(0,(ecg(:,pw+1:end-pw)-ecg(:,1:end-2*pw)).*(ecg(:,pw+1:end-pw)-ecg(:,2*pw+1:end)))); %we apply a filter

    % smoothing:
    peak_signal=[zeros(1,pw),peak_signal,zeros(1,pw)];
    peak_signal_smooth=conv(peak_signal,window,'same');
    peak_signal_smooth=conv(peak_signal_smooth,window,'same');
    peak_signal_smooth=conv(peak_signal_smooth,window,'same');
    u_smooth=conv(u,window,'same');
    u_smooth=conv(u_smooth,window,'same');
    u_smooth=conv(u_smooth,window,'same');
    peak_signal_smooth=peak_signal_smooth./u_smooth;
    peak_signal_normal=peak_signal./peak_signal_smooth; % normalized signal

    t1=(peak_signal_normal>27);
    t2=(1-t1).*(peak_signal_normal>70/9);
    t3=1-t1-t2;
    peak_signal_score=t1+t2.*(peak_signal_normal-7)/20+t3.*(peak_signal_normal)/200; % we apply another filter
end
  
  