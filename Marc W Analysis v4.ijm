////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//PV 2022May
//Edge dynamics Analysis
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//----------Variables use in macro
TCell_ThresholdMin=50;
TCell_ThresholdMax=70000;
TCell_SizeMin=100;

Fib_ThresholdMin=20;
Fib_ThresholdMax=70000;
Fib_SizeMin=100;

Cancer_ThresholdMin=20;
Cancer_ThresholdMax=70000;
Cancer_SizeMin=100;

Test_TCell="D:/Image Analysis Workflows/Marc W/tcell.tif";
Test_Fib="D:/Image Analysis Workflows/Marc W/fib.tif";
Test_Cancer="D:/Image Analysis Workflows/Marc W/cancer.tif";
OpenFileVar1="D:/Image Analysis Workflows/Marc W/Slide CAF1AsPC1_A1 plus 277  mesoFAP one Third of CAR006.nd2";

DispImgSize=500;
DispX=10;
DispY=100;

AnotherSelection=1;
SqROIDim=120;


//----------initialise macro
run("Close All");
run("Clear Results");
roiManager("reset");
run("Set Measurements...", "area fit redirect=None decimal=0");
if (isOpen("Log")) { selectWindow("Log"); run("Close");}
if (isOpen("Summary")) { selectWindow("Summary"); run("Close");}
getDateAndTime(start_year, start_month, start_dayOfWeek, start_dayOfMonth, start_hour, start_minute, start_second, start_msec);
run("Options...", "iterations=0 count=0 black");

//----------user edit parameters
Dialog.create("Do you wish to edit macro parameters?");
Dialog.addMessage("Do you wish to edit macro parameters?");
Dialog.addCheckbox("Yes?", 1) ;
Dialog.show();

UserChoice=Dialog.getCheckbox() ;
if (UserChoice==1) 
	{
		Dialog.create("Adjust processing and analysis variables");
		Dialog.addMessage("\n");
		Dialog.addMessage("T Cell Parameters");
		Dialog.addNumber("TCell Threshold Minimum :", TCell_ThresholdMin);				
		Dialog.addNumber("TCell Threshold Maximum :", TCell_ThresholdMax);
		Dialog.addNumber("TCell Size Minimum :", TCell_SizeMin);
		Dialog.addMessage("\n");
		Dialog.addNumber("CAF Threshold Minimum :", Fib_ThresholdMin);				
		Dialog.addNumber("CAF Threshold Maximum :", Fib_ThresholdMax);
		Dialog.addNumber("CAF Size Minimum :", Fib_SizeMin);
		Dialog.addMessage("\n");
		Dialog.addNumber("Cancer Cell Threshold Minimum :", Cancer_ThresholdMin);				
		Dialog.addNumber("Cancer Cell Threshold Maximum :", Cancer_ThresholdMax);
		Dialog.addNumber("Cancer Cell Size Minimum :", Cancer_SizeMin);
		Dialog.addMessage("\n");
		Dialog.addNumber("Default ROI  dimensions:", SqROIDim);
		Dialog.show();

		TCell_ThresholdMin=Dialog.getNumber();	
		TCell_ThresholdMax=Dialog.getNumber();	
		TCell_SizeMin=Dialog.getNumber();	

		Fib_ThresholdMin=Dialog.getNumber();	
		Fib_ThresholdMax=Dialog.getNumber();	
		Fib_SizeMin=Dialog.getNumber();	

		Cancer_ThresholdMin=Dialog.getNumber();	
		Cancer_ThresholdMax=Dialog.getNumber();	
		Cancer_SizeMin=Dialog.getNumber();	
		SqROIDim=Dialog.getNumber();	
	}


//exit

///*
//----------user select file
OpenFileVar1= File.openDialog("Select you image for analysis"); 	
OriginalFileName=substring(OpenFileVar1, lastIndexOf(OpenFileVar1, "\\")+1, lengthOf(OpenFileVar1));

//----------open file
run("Bio-Formats Importer", "open=OpenFileVar1 color_mode=Default rois_import=[ROI manager] split_channels view=[Standard ImageJ] stack_order=Default");

selectWindow(OriginalFileName+" - C=2");	rename("TCell");
selectWindow(OriginalFileName+" - C=1");	rename("Fib");
selectWindow(OriginalFileName+" - C=0");	rename("Cancer");
close(OriginalFileName+" - C=3");
//exit
//*/

/*
//----------Open Test Files
open(Test_TCell);		rename("TCell");	
open(Test_Fib);		rename("Fib");	
open(Test_Cancer);		rename("Cancer");	
OriginalFileName="Test";
//exit
*/

//----------Identify directory and make output directory
OriginalDir=File.directory;
OutputFileDir=OriginalDir+OriginalFileName+"_Output\\";
File.makeDirectory(OutputFileDir);

//----------T cell processing and segmentation
selectWindow("TCell");	
run("Fire");	
run("Subtract Background...", "rolling=200 stack");
run("Duplicate...", "title=TCellBGSub duplicate");
run("Median...", "radius=1 stack");
run("Kuwahara Filter", "sampling=5 stack");

setThreshold(TCell_ThresholdMin, TCell_ThresholdMax, "raw");
run("Convert to Mask", "background=Dark black create");
run("Analyze Particles...", "size=TCell_SizeMin-Infinity pixel show=Masks stack");
run("Invert LUT");
rename("MASK_TCellFiltered");

getDimensions(MaskWidth, MaskHeight, MaskChannels, MaskSlices, MaskFrames);	

selectWindow("MASK_TCellFiltered");
run("Duplicate...", "title=MASK_TCellFiltered2 duplicate");

selectWindow("MASK_TCellFiltered2");
setSlice(MaskSlices); run("Delete Slice");
setSlice(1);		run("Add Slice");
setSlice(1);		run("Select All");	run("Cut");
setSlice(2);		run("Paste");		run("Select None");

imageCalculator("Difference create stack", "MASK_TCellFiltered","MASK_TCellFiltered2");

rename("TCell_DeltaArea");	
run("Options...", "iterations=1 count=1 black pad do=Close stack");

close("MASK_TCellFiltered2");

selectWindow("MASK_TCellFiltered");
run("Options...", "iterations=1 count=1 black pad do=Close stack");


//----------CAF processing and segmentation
selectWindow("Fib");	
run("Fire");	
run("Subtract Background...", "rolling=500 stack");

selectWindow("MASK_TCellBGSub");
run("Duplicate...", "title=MASK_TCellBGSub16B duplicate");
run("16-bit");
run("Multiply...", "value=10000 stack");

imageCalculator("Subtract create stack", "Fib","MASK_TCellBGSub16B");
rename("FibBGSub");
run("Median...", "radius=5 stack");
run("Gaussian Blur...", "sigma=5 stack");
setThreshold(Fib_ThresholdMin, Fib_ThresholdMax, "raw");
run("Convert to Mask", "background=Dark black create");
run("Analyze Particles...", "size=TCell_SizeMin-Infinity pixel show=Masks stack");
run("Invert LUT");
rename("MASK_FibBGSubFiltered");


//----------Cancer processing and segmentation
selectWindow("Cancer");	
run("Fire");	
run("Subtract Background...", "rolling=500 stack");

imageCalculator("Subtract create stack", "Cancer","MASK_TCellBGSub16B");
rename("CancerBGSub");
run("Median...", "radius=5 stack");
run("Gaussian Blur...", "sigma=5 stack");
setThreshold(Cancer_ThresholdMin, Cancer_ThresholdMax, "raw");
run("Convert to Mask", "background=Dark black create");
run("Analyze Particles...", "size=Cancer_SizeMin-Infinity pixel show=Masks stack");
run("Invert LUT");
rename("MASK_CancerBGSubFiltered");

close("MASK_TCellBGSub16B");

run("Merge Channels...", "c3=MASK_FibBGSubFiltered c2=MASK_CancerBGSubFiltered c1=MASK_TCellFiltered keep");
rename("RGB_Mask");

selectWindow("TCell");	run("Enhance Contrast", "saturated=0.35");
selectWindow("Fib");	run("Enhance Contrast", "saturated=0.35");
selectWindow("Cancer");	run("Enhance Contrast", "saturated=0.35");
run("Merge Channels...", "c3=Fib c2=Cancer c1=TCell keep");
rename("RGB_original");

//----------Cleaning up

close("MASK_CancerBGSubFiltered");
close("MASK_CancerBGSub");
close("CancerBGSub");
close("MASK_FibBGSubFiltered");
close("MASK_FibBGSub");
close("FibBGSub");
close("TCellBGSub");
close("TCell");
close("Fib");
close("Cancer");
close("MASK_TCellBGSub");


//----------Select ROIs for analysis

selectWindow("RGB_original");		setLocation(DispX, DispY, DispImgSize, DispImgSize);
selectWindow("RGB_Mask");		setLocation((DispX+(DispImgSize*1)), DispY, DispImgSize, DispImgSize);
selectWindow("TCell_DeltaArea");		setLocation((DispX+(DispImgSize*2)), DispY, DispImgSize, DispImgSize);
selectWindow("MASK_TCellFiltered");	setLocation((DispX+(DispImgSize*3)), DispY, DispImgSize, DispImgSize);

selectWindow("RGB_Mask");
i2=0;
SelectionName="ROI";
do 
	{
	i2++;
	SelectionName="ROI "+i2;			
	setTool("rectangle");
	run("Specify...", "width=SqROIDim height=SqROIDim x=200 y=200 centered");	
	waitForUser("Select Region. Click OK when done");
	roiManager("Add");	
	roiManager('select', i2-1);	
	roiManager("rename",SelectionName);

	Dialog.create("Do you have another selection?");
	Dialog.addMessage("If you have another selection, check Yes \n\n  if not leave it Uncheecked");
	Dialog.addCheckbox("Yes?", 0) ;
	Dialog.show();
	AnotherSelection=Dialog.getCheckbox() ;
	run("Select None");	
   	} 
	while (AnotherSelection==1);

ROIFileName=OriginalFileName+" Selected ROIs.zip";			ROIFileNameSave=OutputFileDir+ROIFileName;
roiManager("save", ROIFileNameSave);				


//----------Analyse ROIs 

run("Set Measurements...", "area redirect=None decimal=3");

selectWindow("TCell_DeltaArea");	

for (i3=1; i3<=i2; i3++)
{
	SelectionName="ROI"+(i3);
	selectWindow("TCell_DeltaArea");	
	roiManager('select', i3-1);
	run("Analyze Particles...", "summarize stack");
	selectWindow("Summary of TCell_DeltaArea");
	SaveName=OriginalFileName+SelectionName+" Delta Area Summary.txt";
	SaveLog=OutputFileDir+SaveName;
	saveAs("Text", SaveLog);
	close(SaveName);

	selectWindow("MASK_TCellFiltered");	
	roiManager('select', i3-1);
	run("Analyze Particles...", "summarize stack");

	selectWindow("Summary of MASK_TCellFiltered");
	SaveName=OriginalFileName+SelectionName+" Total Area Summary.txt";
	SaveLog=OutputFileDir+SaveName;
	saveAs("Text", SaveLog);
	close(SaveName);

}

selectWindow("RGB_original");
SaveName=OutputFileDir+OriginalFileName+" original RGB";
saveAs("Tiff", SaveName);
close();

selectWindow("RGB_Mask");
SaveName=OutputFileDir+OriginalFileName+" Masks RGB";
saveAs("Tiff", SaveName);
close();

selectWindow("TCell_DeltaArea");
run("Select None");
SaveName=OutputFileDir+OriginalFileName+" DeltaArea";
saveAs("Tiff", SaveName);
close();

selectWindow("MASK_TCellFiltered");
run("Select None");
SaveName=OutputFileDir+OriginalFileName+" TCells";
saveAs("Tiff", SaveName);
close();


exit
















//----------Functions

function EDM_it(image_name)
{
	selectWindow(image_name);
	run("Duplicate...", "duplicate");
	run("Invert", "stack");
	run("Distance Map", "stack");
	run("Fire");
	run("Invert", "stack");


}

