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

begin


;======================================================
;Variables List:
;	t2m--------------Air Temperature (K, TLL)
;======================================================

;global variables
    ;Define parameters

    ;for directory 
    
    ;SCS
    ;g_day_rank=(/135,140,150,155,145,140,150,135,160,145,160,140,160,140,150,125,135,130,140,140,150,135,130,135,145,140,150,140,145,125,150,145,130,140/)
    
    ;BOB
    
    g_strt_yr=1979
    g_lst_yr=2013
    g_yr_len = g_lst_yr-g_strt_yr+1
 

    ; U200 P20-28
    g_day_strt2=70
    g_day_lst2=150
    g_day_comp_len=16
    g_day_rank=(/125,136,133,134,143,108,136,123,119,119,128,105,110,132,134,114,126,112,133,132,93,100,115,114,127,118,123,107,116,112,99,134,113,119,123/)-1-g_day_strt2
    
    g_data3_path ="../data/obv/NCEP-DOE/daily/vwnd1979-2013/vwnd*"
    g_data2_path ="../data/obv/NCEP-DOE/daily/uwnd1979-2013/uwnd*"
    g_data1_path ="/Users/zhenningli/data/obv/NCEP-DOE/hgt.sfc.nc"
    g_font = 0.035
    
        
    g_latS=-10
    g_latN=50
    g_lonW=45
    g_lonE=140
    
    g_latSmp=-5
    g_latNmp=35
    g_lonWmp=70
    g_lonEmp=120

    g_plevel=500
    g_fig_name = "../fig/obv/divUV-2D-dbd-"+g_plevel+"-"+g_lonWmp+"-"+g_lonEmp
        
    g_fig_rank    = (/"(a)","(b)","(c)","(d)","(e)","(f)","(g)","(h)","(i)","(j)","(k)","(l)","(n)","(o)","(p)","(q)","(r)","(s)"/)
    
    day_rank=ispan(0,g_day_comp_len-1,1)
    day_rank=day_rank(::-1)
    g_fig_title = "-"+day_rank+" Days "+g_lonWmp+"-"+g_lonEmp

;Prepare the variables

    ctrl_in1 = addfile(g_data1_path, "r")
    var1  = short2flt(ctrl_in1->hgt(0,{g_latS:g_latN},{g_lonW:g_lonE}))
    var1 = 1013.25*(1-var1*0.0065/288.15)^5.25145
    var1_line=dim_min_n_Wrap(var1,1)
    var1_line=dim_median_n(var1,1)
    
    
    ctrl_in2_files = systemfunc("ls "+g_data2_path)
    setfileoption("nc","SuppressClose",False) ; close too many files
    ctrl_in2     = addfiles (ctrl_in2_files, "r")   ; note the "s" of addfile
    ListSetType (ctrl_in2, "join")
    var2  =short2flt(ctrl_in2[:]->uwnd(:,g_day_strt2:g_day_lst2,{:100},{g_latS:g_latN},{g_lonW:g_lonE}))
    var2_366  =short2flt(ctrl_in2[1::4]->uwnd(:,g_day_strt2:g_day_lst2,{:100},{g_latS:g_latN},{g_lonW:g_lonE}))
    var2_dim = dimsizes(var2)
    var2_data = new((/g_yr_len,var2_dim(1),var2_dim(2),var2_dim(3),var2_dim(4)/),"float")
    copy_VarMeta(var2,var2_data)
   
    ; Merge normal and leap years 
    sp = 0
    do ii=0,g_yr_len-1
        if (mod((ii-1),4) .eq. 0) then
            var2_data(ii,:,:,:,:) = var2_366((ii-1)/4,:,:,:,:)
            sp=sp+1
        else
            var2_data(ii,:,:,:,:) = var2(ii-sp,:,:,:,:)
        end if
    end do
    
    ctrl_in3_files = systemfunc("ls "+g_data3_path)
    setfileoption("nc","SuppressClose",False) ; close too many files
    ctrl_in3     = addfiles (ctrl_in3_files, "r")   ; note the "s" of addfile
    ListSetType (ctrl_in3, "join")
    var3  =short2flt(ctrl_in3[:]->vwnd(:,g_day_strt2:g_day_lst2,{:100},{g_latS:g_latN},{g_lonW:g_lonE}))
    var3_366  =short2flt(ctrl_in3[1::4]->vwnd(:,g_day_strt2:g_day_lst2,{:100},{g_latS:g_latN},{g_lonW:g_lonE}))
    var3_dim = dimsizes(var3)
    var3_data = new((/g_yr_len,var3_dim(1),var3_dim(2),var3_dim(3),var3_dim(4)/),"float")
    copy_VarMeta(var3,var3_data)
   
    ; Merge normal and leap years 
    sp = 0
    do ii=0,g_yr_len-1
        if (mod((ii-1),4) .eq. 0) then
            var3_data(ii,:,:,:,:) = var3_366((ii-1)/4,:,:,:,:)
            sp=sp+1
        else
            var3_data(ii,:,:,:,:) = var3(ii-sp,:,:,:,:)
        end if
    end do


    ;var2_rmean= runave_n_Wrap(var2_data, 3, 0, 1)
    ;var3_rmean= runave_n_Wrap(var3_data, 3, 0, 1)

    var2_rmean= var2_data
    var3_rmean= var3_data
    delete([/var2_data, var3_data/])
    var2_clim=dim_avg_n_Wrap(var2_rmean, 0)
    var3_clim=dim_avg_n_Wrap(var3_rmean, 0)
    
    var_div=uv2dvF_Wrap(var2_rmean(:,:,{g_plevel},:,:),var3_rmean(:,:,{g_plevel},:,:))
    var_div_clim=dim_avg_n_Wrap(var_div,0)

    var2_cmp = var2_rmean(:,0:g_day_comp_len-1,:,:,:)
    var3_cmp = var3_rmean(:,0:g_day_comp_len-1,:,:,:)
    var_div_cmp_mx = var_div(:,0:g_day_comp_len-1,:,:)
    do ii=0,g_yr_len-1
        var2_cmp(ii,:,:,:,:)=var2_rmean(ii,g_day_rank(ii)-g_day_comp_len+1:g_day_rank(ii),:,:,:)
        ;var2_cmp(ii,:,:,:,:)=var2_cmp(ii,:,:,:,:)-var2_clim(g_day_rank(ii)-g_day_comp_len+1:g_day_rank(ii),:,:,:)
        var3_cmp(ii,:,:,:,:)=var3_rmean(ii,g_day_rank(ii)-g_day_comp_len+1:g_day_rank(ii),:,:,:)
        ;var3_cmp(ii,:,:,:,:)=var3_cmp(ii,:,:,:,:)-var3_clim(g_day_rank(ii)-g_day_comp_len+1:g_day_rank(ii),:,:,:)
        var_div_cmp_mx(ii,:,:,:)=var_div(ii,g_day_rank(ii)-g_day_comp_len+1:g_day_rank(ii),:,:)
        ;var_div_cmp_mx(ii,:,:,:)=var_div_cmp_mx(ii,:,:,:)-var_div_clim(g_day_rank(ii)-g_day_comp_len+1:g_day_rank(ii),:,:)
    end do
    var2_cmp:=dim_avg_n_Wrap(var2_cmp,0)
    var3_cmp:=dim_avg_n_Wrap(var3_cmp,0)
    var_div_cmp_mx:=dim_avg_n_Wrap(var_div_cmp_mx,0)
; ==============================================================
; Mission 3. Set plot parameters and plot
; ==============================================================

;  wks = gsn_open_wks("pdf","up_T_surface_cte_mean_250-400hPa")  ; open a ps file
;  wks = gsn_open_wks("x11","diabatic_heat_250-500hPa")  ; open a ps file

  plot_sh = new((/g_day_comp_len/),graphic)
  plot_V = new((/g_day_comp_len/),graphic)
  plot_cn_max = new((/g_day_comp_len/),graphic)
  plot_cn_max_pre = new((/g_day_comp_len/),graphic)
;  plot_sh = new((/2/),graphic)
;  plot_V = new((/2/),graphic)

;  gsn_define_colormap(wks,"BlAqGrYeOrReVi200") ; choose a colormap 
;   gsn_define_colormap(wks,"Rainbow") ; choose a colormap
;   gsn_define_colormap(wks,"BlGrYeOrReVi200") ; choose a colormap
;  gsn_define_colormap(wks,"precip4_diff_19lev")
;  gsn_define_colormap(wks,"precip_diff_12lev")
; gsn_define_colormap(wks,"BkBlAqGrYeOrReViWh200")
; gsn_define_colormap(wks,"WhiteBlueGreenYellowRed")


;-----------------------------------------------------------------------------
  res                  = True       ; use plot options

  res@cnFillOn             = True               ; turn on color for contours
  res@cnLinesOn            = False              ; turn off contour lines
  res@cnLineLabelsOn       = False              ; turn off contour line labels



;  res@mpLandFillColor       = "gray"            ; set land to be gray

;  res@cnLevelSelectionMode = "ExplicitLevels"   ; set manual contour levels
;  res@cnLevels = (/-5,-4.5,-4,-3.5,-3,-2.5,-2,-1.5,-1,-0.5,0,0.5,1,1.5,2,2.5,3,3.5,4,4.5,5/)
;   res@cnLevels = ispan(0,60,10)
;  res@cnFillColors =(/-1,20,47,57,94,127,152/)
;    res@cnLevelSelectionMode = "ExplicitLevels"   ; set manual contour levels
;    res@cnLevels =    (/-0.8,-0.4,-0.2, 0.0, 0.2, 0.4, 0.6, 0.8, 1.0, 1.5, 2.0, 2.5, 3.0/)
;    res@cnFillColors =(/   2,  18,  34,  52,  61,  68,  77,  82,  87,  91,  95,  99, 100, 102/)

 res@cnLevelSelectionMode  = "ManualLevels" ; set manual contour levels
 res@cnMinLevelValF        = -3e-6         ; set min contour level
 res@cnMaxLevelValF        = 3e-6          ; set max contour level
 res@cnLevelSpacingF       = 3e-7          ; set contour interval

;  res@cnFillColors =(/2,4,7,8,8,9,11,13/)


  res@gsnFrame         = False
  res@gsnDraw  = False
  
;  res@gsnSpreadColors      = True               ; use full color map
;  res@gsnSpreadColorStart  = 2               ; start at color 17
;  res@gsnSpreadColorEnd    = 14                ; end at color 200

;  res@gsnPanelLabelBar    = True   ;Turn on panel labelbar
  res@gsnStringFontHeightF = g_font

  ;res@gsnMaximize      = True       ; fill up the page
  res@gsnAddCyclic   = False
  res@gsnPaperOrientation = "portrait"
  ;res@gsnContourZeroLineThicknessF = 2.  ;set thickness of zero


  res@lbLabelBarOn = False   ; turn off the label bar
  res@lbOrientation          = "vertical"
  res@lbLabelFontHeightF  = g_font              ; make labels smaller
  res@lbLabelStride = 2 


  res@mpFillOn   = False     ; turn off gray continents
  res@mpGeophysicalLineThicknessF = 2
  res@mpGeophysicalLineColor      = "black";"white" 
  res@mpFillDrawOrder="PostDraw"
  res@mpMaxLatF  = g_latNmp
  res@mpMinLatF  = g_latSmp
  res@mpMaxLonF  = g_lonEmp
  res@mpMinLonF  = g_lonWmp

;  res@mpShapeMode = "FreeAspect" 

;  res@vpWidthF = 0.8
;  res@vpHeightF = 0.6

;  res@tmXBMajorOutwardLengthF = -0.
;  res@tmYLMajorOutwardLengthF = -0.
;  res@tmYRMajorOutwardLengthF = -0.
  
;  res@tmXBMinorOutwardLengthF = -0.
;  res@tmYLMinorOutwardLengthF = -0.
;  res@tmYRMinorOutwardLengthF = -0.
    
     ; now change the size of the tickmark labels
  res@tmXBTickSpacingF = 30
  res@tmYLTickSpacingF = 15
  res@tmXBLabelFontHeightF = g_font
; res@tmXBLabelFontAspectF = 1.6
  res@tmXBLabelFontThicknessF = 2.0
  res@tmYLLabelFontHeightF = g_font
; res@tmYLLabelFontAspectF = 1.3
  res@tmYLLabelFontThicknessF = 2.0
; res@tmYLLabelFontQuality =
;-----------------------------------------------------------------------------
     
  res@gsnLeftString = ""
  res@gsnRightString = ""
       
  vcres = True
  vcres@gsnDraw          = False           ; don't draw
  vcres@gsnFrame         = False           ; don't advance frame
  vcres@gsnRightString   = " "             ; turn off right string
  vcres@gsnLeftString    = " "             ; turn off left string
  vcres@gsnCenterString    = " "
 
  vcres@vcRefAnnoOn      = True
  vcres@vcRefAnnoOrthogonalPosF = -1.0             ; move ref vector up
  vcres@vcRefMagnitudeF         = 10.0             ; define vector ref mag
  vcres@vcRefLengthF            = 0.045            ; define length of vec ref
  vcres@vcGlyphStyle            = "CurlyVector"    ; turn on curly vectors
  vcres@vcMinDistanceF          = 0.03
  vcres@vcRefAnnoString1  = "10 m/s"
  vcres@vcRefAnnoString2  = ""
  vcres@vcRefAnnoFontHeightF = 0.02
 
  vcres@vcLineArrowThicknessF     = 2.0    ;thickness of vector
  vcres@vcLineArrowHeadMinSizeF   = 0.01
  vcres@vcLineArrowHeadMaxSizeF   = 0.01
 

  res3                  = True       ; use plot options
  res3@cnFillOn         = False;True       ; Fill contours
  res3@cnLinesOn        = True      ; turn off contour lines
;for tp masking
  res3@gsnFrame         = False
  res3@gsnDraw  = False
  res3@cnLineLabelsOn   = False      ; turn off contour line labels
  res3@cnLineThicknessF = 4 
  res3@cnInfoLabelOn = False
 
 
  res3@cnLevelSelectionMode="ExplicitLevels"
  res3@cnLevels = (/0./)
  res3@cnLineColor      = "Black"
  res3@gsnLeftString      = " "
  res3@gsnRightString      = " "

  res4=res3
  res4@cnLineColor="Grey"

;************************************************
; create panel
;************************************************
  resP                     = True                ; modify the panel plot
                                                 ; new resource added in NCL V6.4.0
; resP@gsnPanelMainString = "A plot with a common label bar"
                                                 ; use this for NCL V6.3.0 and earlier
  resP@gsnPanelLabelBar    = True                ; add common colorbar
  resP@lbLabelFontHeightF  = 0.015               ; make labels smaller 
  wks = gsn_open_wks("eps",g_fig_name)  ; open a ps file
 
 gsn_define_colormap(wks,"ViBlGrWhYeOrRe")
  do ii=0,g_day_comp_len-1
    res@gsnRightString=""
    res@gsnLeftString=g_fig_rank(ii)
    res@gsnCenterString=g_fig_title(ii)
    plot_sh(ii) = gsn_csm_contour_map(wks,var_div_cmp_mx(ii,:,:),res) ; create a default plot
    plot_cn_max(ii) = gsn_csm_contour(wks,var2_cmp(ii,{g_plevel},:,:),res3)

    plot_V(ii) = gsn_csm_vector(wks,var2_cmp(ii,{g_plevel},:,:),var3_cmp(ii,{g_plevel},:,:),vcres) 
    overlay(plot_sh(ii),plot_V(ii))
    if ii .gt. 0 then
        plot_cn_max_pre(ii) = gsn_csm_contour(wks,var2_cmp(ii-1,{g_plevel},:,:),res4)
        overlay(plot_sh(ii),plot_cn_max_pre(ii))
    end if
    overlay(plot_sh(ii),plot_cn_max(ii))
  end do
  gsn_panel(wks,plot_sh,(/4,4/),resP)

end

