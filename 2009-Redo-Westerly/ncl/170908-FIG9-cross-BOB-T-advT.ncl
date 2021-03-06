;*************************************************************
;Aim: Cal MAM detrended T2m standard deviation
;
;Mission:
;   1. Read data from NCEP-DOE data
;   2. Post-post process
;   3. Output to yearly files
;                       Zhenning Li
;                       2015-05-05
;Last Edited:
;   2015-03-01  Create
;   2015-03-03  Change to fit HEAT Experiment
;   2015-04-05  Change to fit Team Server
;   2015-04-08  Change to fit ECMWF MONLTM MEAN 
;   2015-04-18  Change to caculate Q1
;   2015-04-18  Change to caculate daily Q1 in NCEP-DOE
;   2015-12-01  Change to fit T2M
;*************************************************************

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCL_SELFLIB/file_io.ncl"
begin


;======================================================
;Variables List:
;	var1--------------U (K, TLL)
;======================================================

;global variables
;Define parameters

    ;for directory 
    g_strt_yr=1979
    g_lst_yr=2013
    g_strt_day=19790101
    g_lst_day=20131231
    g_yr_len = g_lst_yr-g_strt_yr+1
    
    ; U200 P21-24
    g_day_strt2=89
    g_day_lst2=119
    



    g_var_name1 = "r"
;    g_data2_path ="../../data/obv/NCEP-DOE/daily/uwnd1979-2013/uwnd.198[2-3].nc"
    g_data2_path="/home/yangsong3/data/observation/ERA-interim/pressure/air/"
    g_data_clim="/home/yangsong3/data/observation/ERA-interim/pressure/daily-clim/air.mean.nc"
    g_data1_path ="/home/yangsong3/L_Zealot/project/PRE_PRO_SHARE/data/TOPO/USGS_gtopo30_0.23x0.31_remap_c061107.nc"
    g_data_adv_path="/home/yangsong3/data/observation/ERA-interim/pressure/daily-clim/interim.75-120.advT.nc"
    g_font = 0.02
    
    ;BOB Early
    g_special_year=(/ 1990, 1999, 2000, 2006, 2009, 2012, 2015/) 
    g_day_rank=(/102, 93, 101, 105, 99, 106, 101/)-1
 
    ;g_comp_years=(/1984, 1990, 1991, 1994, 1996, 1999, 2000, 2001, 2002, 2006, 2008, 2009, 2011/)
    ;g_comp_years=(/1984, 1990, 1991, 1999, 2000, 2006, 2009/)
    ; Early
    ; Late
    ;g_comp_years=(/1980, 1981, 1985, 1992, 1993, 1997, 1998, 2010/)

    g_latS=0
    g_latN=40
    g_lonW=75
    g_lonE=100
    ; create an array of desired pressure levels:
    g_fig_name = "../../fig/FINAL/FIG9a-T-diff-sec-pbp"
        
    g_fig_rank    = (/"(a)","(b)","(c)","(d)","(e)","(f)","(g)","(h)","(i)","(j)","(k)","(l)","(n)","(o)"/)
;    g_fig_rank    = (/"(e)","(f)","(g)","(h)","(i)","(j)","(k)","(l)","(n)","(o)"/)
    g_fig_title = "Day 90-120 T Grad & Adv (Early-Clim)"

;Prepare the variables
    ; Height --> Pressure
    ctrl_in1 = addfile(g_data1_path, "r")
    var1  = ctrl_in1->PHIS({g_latS:g_latN},{g_lonW:g_lonE})
    var1 = 1013.25*(1-(var1/9.8)*0.0065/288.15)^5.25145
    var1_line=dim_avg_n_Wrap(var1,1)
    var1_line=dim_median_n(var1,1)

    ;; Determine the terrain
    dimvar1=dimsizes(var1_line)
    topo2d = new((/50,dimvar1/),"float")
    topo2d!0="level"
    topo2d&level=fspan(200,1000,50)
    topo2d!1=var1!0
    topo2d&lat=var1&lat
    ;topo2d@_FillValue=-999
    do ii= 0, dimvar1-1
        topo2d(:,ii)=where(topo2d&level .lt. var1_line(ii),0,1)
        ;topo2d(:,ii)=where(topo2d&level .lt. var1_line(ii),0,topo2d@_FillValue)
    end do

    clim_file=addfile(g_data_clim,"r")
    var2_clim=clim_file->air(g_day_strt2:g_day_lst2,{200:1000},{g_latS:g_latN},{g_lonW:g_lonE})
    var2_sample=var2_clim
    var2_sample=0
    var2_clim:=dim_avg_n_Wrap(var2_clim,3)
    var2_clim:=dim_avg_n_Wrap(var2_clim,0)

    n_cases=dimsizes(g_special_year)
    do ii=0,n_cases-1
        sample_file=addfile(g_data2_path+"air.interim."+tostring(g_special_year(ii))+".nc","r")
        print(ii+"/"+n_cases)
        var2_single=sample_file->air(g_day_strt2:g_day_lst2,{200:1000},{g_latS:g_latN},{g_lonW:g_lonE})
        var2_sample=var2_sample+var2_single
    end do
    var2_sample=var2_sample/n_cases
    var2_sample := dim_avg_n_Wrap(var2_sample,3)
    var2_sample := dim_avg_n_Wrap(var2_sample,0)
    var2_comp_clim_ano = var2_clim
    var2_comp_clim_ano = var2_sample - var2_clim
    var2_comp_clim_ano = dim_rmvmean_n_Wrap(var2_comp_clim_ano, 1)
    var2_clim = dim_rmvmean_n_Wrap(var2_clim, 1)


    adv_file=addfile(g_data_adv_path,"r")
    var2_adv=adv_file->advT(:,g_day_strt2-74:g_day_lst2-74,{200:1000},{g_latS:g_latN},{g_lonW:g_lonE})
    
    var2_adv=var2_adv*86400
    var2_adv := dim_avg_n_Wrap(var2_adv,4)
    var2_adv := dim_avg_n_Wrap(var2_adv,1)
    var2_adv_clim := dim_avg_n_Wrap(var2_adv,0)
    
    n_cases=dimsizes(g_special_year)
    var2_adv_smp=var2_adv(0:n_cases-1,:,:)
    do ii=0,n_cases-1
        var2_adv_smp(ii,:,:)=var2_adv(g_special_year(ii)-1979,:,:)
    end do
    var2_adv_smp_mean=dim_avg_n_Wrap(var2_adv_smp,0)
    var2_adv_ano=var2_adv_smp_mean
    var2_adv_ano=var2_adv_smp_mean-var2_adv_clim
    var2_adv_ano=where(var2_adv_ano .lt. 0.05, var2_adv_ano@_FillValue, var2_adv_ano)

;    var2_comp_clim_ano = where(abs(var2_comp_clim_ano) .lt. 0.2,var2_comp_clim_ano@_FillValue, var2_comp_clim_ano)
; ==============================================================
; Mission 3. Set plot parameters and plot
; ==============================================================

  wks = gsn_open_wks("eps",g_fig_name)  ; open a ps file
;  wks = gsn_open_wks("pdf","up_T_surface_cte_mean_250-400hPa")  ; open a ps file
;  wks = gsn_open_wks("x11","diabatic_heat_250-500hPa")  ; open a ps file

  plot_sh = new((/1/),graphic)
  plot_cn_pos = new((/1/),graphic)
  plot_cn_neg = new((/1/),graphic)
  plot_sig = new((/1/),graphic)
  plot_topo = new((/1/),graphic)

;  gsn_define_colormap(wks,"BlAqGrYeOrReVi200") ; choose a colormap 
;   gsn_define_colormap(wks,"Rainbow") ; choose a colormap
;   gsn_define_colormap(wks,"BlGrYeOrReVi200") ; choose a colormap
;  gsn_define_colormap(wks,"precip4_diff_19lev")
;  gsn_define_colormap(wks,"precip_diff_12lev")
; gsn_define_colormap(wks,"BkBlAqGrYeOrReViWh200")
; gsn_define_colormap(wks,"WhiteBlueGreenYellowRed")
 gsn_define_colormap(wks,"BlRe")
 ;gsn_define_colormap(wks,"NCV_jaisnd")
; gsn_define_colormap(wks,"NCV_jaisnd")


;-----------------------------------------------------------------------------
  res                  = True       ; use plot options
  res@gsnFrame         = False
  res@gsnDraw  = False
 
  res@cnFillOn             = True               ; turn on color for contours
  res@cnLinesOn            = False              ; turn off contour lines
  res@cnLineLabelsOn       = False              ; turn off contour line labels
  res@cnInfoLabelOn        = False             ; turn off info label

  res@tmYROn=False
  res@tmYRMode="Automatic"
 res@cnLevelSelectionMode  = "ExplicitLevels" ; set manual contour levels
 res@cnLevels=(/-4.0,-2.0,-1.5,-1.0,-0.75,-0.5, -0.25,-0.1,0,0.1,0.25,0.5,0.75,1.0,1.5,2.0,4.0/)
 ; res@cnFillColors =(/2,4,7,8,8,9,11,13/)
 res@vpWidthF = 0.7
 res@vpHeightF = 0.4
; res@cnMissingValFillColor="black"


 
  res@gsnSpreadColors      = True               ; use full color map
;  res@gsnSpreadColorStart  = 2               ; start at color 17
;  res@gsnSpreadColorEnd    = 14                ; end at color 200

;  res@gsnPanelLabelBar    = True   ;Turn on panel labelbar
  res@gsnStringFontHeightF = g_font

;  res@gsnMaximize      = True       ; fill up the page
;  res@gsnAddCyclic   = True;False
;  res@gsnPaperOrientation = "portrait"

  res@tiYAxisString=""
  res@lbLabelBarOn = True   ; turn off the label bar
  ;res@lbOrientation          = "vertical"
  res@lbLabelFontHeightF  = g_font              ; make labels smaller
; res@lbLabelStride = 2
  res@tmXBTickSpacingF = 10
;  res@tmYLValues = fspan(100,1000,10)
;  res@tmYLLabels = fspan(100,1000,10)
   res@tmYLMajorOutwardLengthF=0
   res@tmYLMajorLengthF=0.0
  res@tmXBLabelFontHeightF = g_font
; res@tmXBLabelFontAspectF = 1.6
  res@tmXBLabelFontThicknessF = g_font
  res@tmYLLabelFontHeightF = g_font
; res@tmYLLabelFontAspectF = 1.3
  res@tmYLLabelFontThicknessF = g_font
; res@tmYLLabelFontQuality =
;-----------------------------------------------------------------------------


  resC                  = True       ; use plot options
  resC@cnLinesOn            = True              ; turn off contour lines
  resC@cnLineLabelsOn       = False              ; turn off contour line labels
  resC@cnInfoLabelOn        = False             ; turn off info label
  resC@gsnFrame         = False
  resC@gsnDraw  = False
  resC@gsnMaximize      = False       ; fill up the page
  resC@gsnAddCyclic   = False
  resC@gsnContourZeroLineThicknessF = 3.  ;set thickness of zero
  resC@cnLineThicknessF=2.0
  resC@cnLevelSelectionMode = "ExplicitLevels"  ; use explicit levels
  resC@cnLevels=fspan(0,5,6)
  resC@cnLineDashPattern = 0
;  resC@cnLevels             = ispan(-20,40,10 )   ; set the contour levels
  resC@gsnLeftString=""
  resC@gsnRightString=""

  resC2=resC
  resC2@cnLineDashPattern = 1
  resC2@cnLevels:=-resC2@cnLevels

;----------Set res sig-----------
    res_sig                  = True       ; use plot options
    res_sig@cnFillOn         = True       ; Fill contours
    res_sig@cnLinesOn        = False;True      ; turn off contour lines
    res_sig@gsnFrame         = False
    res_sig@gsnDraw  = False
    ;res_sig@gsnAddCyclic   = False 
    res_sig@cnLineLabelsOn   = False      ; turn off contour line labels
    res_sig@cnLineThicknessF = 2
    res_sig@cnInfoLabelOn = False
    res_sig@cnMonoFillPattern    = True;False
    res_sig@cnFillPattern = 17
    res_sig@cnMonoFillScale = True
    res_sig@cnFillScaleF = 1.5
    res_sig@cnMonoFillColor = True
    res_sig@cnFillColor  =  "darkgreen"
    res_sig@cnFillDotSizeF = 0.005

    res_sig@lbLabelBarOn = False;True   ; turn off the label bar

    ;  res_sig@cnLevelSelectionMode="ExplicitLevels"
    res_sig@gsnLeftString      = " "
    res_sig@gsnRightString      = " "

  resT=resC
  resT@cnFillOn             = True               ; turn on color for contours
  resT@cnLinesOn            = False   ; turn off contour lines
  delete(resT@gsnContourZeroLineThicknessF)
  resT@cnFillColors=(/"white","black"/)
  resT@cnLevelSelectionMode  = "ExplicitLevels" ; set manual contour levels
  resT@cnLevels       := 0.5        ; set contour interval
;
  resT@lbLabelBarOn = False   ; turn off the label bar
;  resT@trYReverse=True
do ii=0,0
    res@gsnRightString=""
    res@gsnLeftString=g_fig_rank(ii)
    res@gsnCenterString=g_fig_title(ii)


    plot_sh(ii) = gsn_csm_pres_hgt(wks, var2_comp_clim_ano, res ) 
    plot_cn_pos(ii) = gsn_csm_contour(wks,var2_clim,resC)
    plot_cn_neg(ii) = gsn_csm_contour(wks,var2_clim,resC2)
    plot_topo(ii) = gsn_csm_contour(wks,topo2d,resT)
     plot_sig(ii) = gsn_csm_contour(wks,var2_adv_ano,res_sig)
 
    overlay(plot_sh(ii),plot_cn_neg(ii))
    overlay(plot_sh(ii),plot_cn_pos(ii))
    overlay(plot_sh(ii),plot_sig(ii))
   overlay(plot_sh(ii),plot_topo(ii))
    draw(plot_sh)
    frame(wks)
end do
end

