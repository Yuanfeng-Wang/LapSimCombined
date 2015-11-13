function [ RawResults,PointResults ] = RPMLimitingAnalysis(CarFcn, TrackFcn)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

Track = TrackFcn();

GearRatios = (3:0.5:5);
S1 = length(GearRatios);

RPMCutOffs = (5000:-500:1500);
S2 = length(RPMCutOffs);

RawResults = zeros(S1*2,8,S2);

EnduranceLength = 866142; %22km in inches

EnduranceLaps = EnduranceLength/Track.Length;

for i = 1:S1
    Car = CarFcn();
    Track = TrackFcn();
    
    GR = GearRatios(i);
    Car.Driveline.SetGearRatios(GR, Car.Motor.OutputCurve);
    
    Tele = Simulate(Car,Track);
    
    TimeAutoX = sum(cell2mat(Tele.Results(1)));
    Time75 = cell2mat(Tele.Results(4));
    MaxG = Car.Tire.MaxLateralAcceleration;
    TimeSkid = 2*pi*sqrt(9.1/(9.81*MaxG));
    
    for j = 1:S2
        RPM = RPMCutOffs(j) * GR;
        
        Car.Driveline.SetRPMLimit(RPM);
        
        [Energy, EndTime, TF ] = EnduranceSimulationBasic(Car,Track,EnduranceLength);

        RawResults(i,:,j) = [TimeAutoX,Time75,TimeSkid,EndTime,Energy,TF,RPM,GR];      
    end   
end

% parfor i = S1+1:S1*2 
%     Car = CarBuilderSS('Electric', 6);
%     Track = FSAELincoln2013;
%     TF=1;
% 
%     Car.Weight = Car.Weight - 38;
%     Car.Battery.Capacity = 4.73;
%     GR = GearRatios(i-S1);
%     Car.Driveline.GearRatio = GR;
%     
%     Tele = Simulate(Car,Track);
%     
%     TimeAutoX = sum(cell2mat(Tele.Results(1)));
%     Time75 = cell2mat(Tele.Results(4));
%     MaxG = Car.Tire.MaxLateralAcceleration;
%     TimeSkid = 2*pi*sqrt(9.1/(9.81*MaxG));
%     
%     AxleOutputCurve = Car.Motor.OutputCurve;
%     
%     for j = 1:S2
%         
%         RPM = RPMCutOffs(j);
%         
%         Car.Motor.OutputCurve(RPM+2:end,:) = [];
%     
%         [Energy, EndTime, TF ] = EnduranceSimulation(Car,Track,EnduranceLength,TF);
%    
%         RawResults(i,:,j) = [TimeAutoX,Time75,TimeSkid,EndTime,Energy,TF,RPM,GR];
%     
%         if TF > 1
%             TF = 1;
%         end
%         
%     end
%     
%     Car.Motor.OutputCurve = AxleOutputCurve;
%     
% end


LapTime = RawResults(:,4)/EnduranceLaps;
LapEnergy = RawResults(:,5)/EnduranceLaps;

EFArray = (min(LapTime)./LapTime).*(min(LapEnergy)./LapEnergy).^2;

PointResults = zeros(S1*2,6);

CompMinTimes = [3.950,51.569,4.827,1820.652,1820.652/ceil(EnduranceLaps)];
OurMinTimes = [min(RawResults(:,1:4)),min(LapTime)];
OverallMinTimes = min(CompMinTimes, OurMinTimes);


for i = 1:S1*2
    for j = 1:S2
        PointResults(i,:,j) = PointCalculator(OverallMinTimes,min(LapEnergy),min(EFArray),[RawResults(i,1:4),LapTime(i)],LapEnergy(i));
    end

end

scatter3(GearRatios,RPMCutoffs,PointResults(1:S1,end,:),'ro')
hold on
scatter3(GearRatios,RPMCutoffs,PointResults(S1+1:2*S1,end,:),'bo')
grid on

end


