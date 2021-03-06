function RetBathy=GRID_SmoothNegative_rx0(MSK, Hobs, rx0max)
% this program does bathymetry smoothing
% GRID_SmoothNegative_rx0(MSK, Hobs, rx0max)
%
% ---MSK(eta_rho,xi_rho) is the mask of the grd
%      1 for sea
%      0 for land
% ---Hobs(eta_rho,xi_rho) is the raw depth of the grid
% ---rx0max is the target rx0 roughness factor
[eta_rho, xi_rho]=size(Hobs);

ListNeigh=[1 0;
	   0 1;
	   -1 0;
	   0 -1];
RetBathy=Hobs;

nbModif=0;
tol=0.000001;
while(true)
  IsFinished=1;
  for iEta=1:eta_rho
    for iXi=1:xi_rho
      if (MSK(iEta, iXi) == 1)
	for ineigh=1:4
	  iEtaN=iEta+ListNeigh(ineigh,1);
	  iXiN=iXi+ListNeigh(ineigh,2);
	  if (iEtaN <= eta_rho && iEtaN >= 1 && ...
	      iXiN <= xi_rho && iXiN >= 1 && ...
	      MSK(iEtaN, iXiN) == 1)
	    UpperBound=RetBathy(iEtaN, iXiN)*(1+rx0max)/(1-rx0max);
	    if (RetBathy(iEta,iXi) > UpperBound + tol)
	      IsFinished=0;
	      TheDelta=abs(UpperBound-RetBathy(iEta, iXi));
	      RetBathy(iEta, iXi)=UpperBound;
	      nbModif=nbModif+1;
	    end;
	  end;
	end;
      end;
    end;
  end;
  if (IsFinished == 1)
    break;
  end;
end;
disp(['     nbModif=' num2str(nbModif)]);
