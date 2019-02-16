//
// shapedemo: testbed for OpenVG APIs
// Anthony Starks (ajstarks@gmail.com)
//
#include <linux/input.h>
#include <string.h>


#include "touch.h"


#include <signal.h>

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <dirent.h>

#include "VG/openvg.h"
#include "VG/vgu.h"
#include "fontinfo.h"
#include "shapes.h"



#include <pthread.h>
#include <fftw3.h>
#include <math.h>

#define KWHT  "\x1B[37m"
#define KYEL  "\x1B[33m"

#define PATH_CONFIG "/home/pi/rpidatv/scripts/portsdown_config.txt"
char ImageFolder[]="/home/pi/rpidatv/image/";

int fd=0;
int wscreen, hscreen;
float scaleXvalue, scaleYvalue; // Coeff ratio from Screen/TouchArea


typedef struct {
	int r,g,b;
} color_t;


typedef struct {
	char Text[255];
	color_t  Color;
} status_t;

#define MAX_STATUS 10
typedef struct {
	int x,y,w,h;

	status_t Status[MAX_STATUS];
	int IndexStatus;
	int NoStatus;
	int LastEventTime;
} button_t;

#define MAX_BUTTON 25
int IndexButtonInArray=0;
button_t ButtonArray[MAX_BUTTON];
int IsDisplayOn=0;
#define TIME_ANTI_BOUNCE 500

//GLOBAL PARAMETERS

int fec;
int SR;
char ModeInput[255];
char freqtxt[255];

// Values to be stored in and read from rpidatvconfig.txt:

int TabSR[5]= {250,333,500,1000,2000};
int TabFec[5]={1,2,3,5,7};
char TabModeInput[5][255]={"CAMMPEG-2","CAMH264","PATERNAUDIO","FILETS","CARRIER"};
char TabFreq[5][255]={"71","146.5","437","1249","1255"};

int Inversed=0;//Display is inversed (Waveshare=1)

pthread_t thfft,thbutton;

/***************************************************************************//**
 * @brief Looks up the value of Param in PathConfigFile and sets value
 *        Used to look up the configuration from rpidatvconfig.txt
 *
 * @param PatchConfigFile (str) the name of the configuration text file
 * @param Param the string labeling the parameter
 * @param Value the looked-up value of the parameter
 *
 * @return void
*******************************************************************************/}

int mymillis()
{
        struct timeval tv;
        gettimeofday(&tv, NULL);
        return (tv.tv_sec) * 1000 + (tv.tv_usec)/1000;
}


void coordpoint(VGfloat x, VGfloat y, VGfloat size, VGfloat pcolor[4]) {
	setfill(pcolor);
	Circle(x, y, size);
	setfill(pcolor);
}

	fftwf_complex *fftout=NULL;
#define FFT_SIZE 256

int FinishedButton=0;

void *DisplayFFT(void * arg)
{
	FILE * pFileIQ = NULL;
	int fft_size=FFT_SIZE;
	fftwf_complex *fftin;
	fftin = (fftwf_complex *)fftwf_malloc(sizeof(fftwf_complex) * fft_size);
	fftout = (fftwf_complex *)fftwf_malloc(sizeof(fftwf_complex) * fft_size);
	fftwf_plan plan ;
	plan = fftwf_plan_dft_1d(fft_size, fftin, fftout, FFTW_FORWARD, FFTW_ESTIMATE );

	system("mkfifo fifo.iq");
	printf("Entering FFT thread\n");
	pFileIQ = fopen("fifo.iq", "r");

	while(FinishedButton==0)
	{
		int Nbread; // value set later but not used
		//int log2_N=11; //FFT 1024 not used?
		//int ret; // not used?

		Nbread=fread( fftin,sizeof(fftwf_complex),FFT_SIZE,pFileIQ);
		fftwf_execute( plan );

		//printf("NbRead %d %d\n",Nbread,sizeof(struct GPU_FFT_COMPLEX));

		fseek(pFileIQ,(1200000-FFT_SIZE)*sizeof(fftwf_complex),SEEK_CUR);
	}
	fftwf_free(fftin);
	fftwf_free(fftout);
}

void ProcessLeandvb()
{
   #define PATH_SCRIPT_LEAN "sudo /home/pi/rpidatv/scripts/leandvb_rx.sh 2>&1"
   char *line=NULL;
   size_t len = 0;
    ssize_t read;

	// int rawX, rawY, rawPressure; //  not used
	FILE *fp;
	// VGfloat px[1000];  // Variable not used
	// VGfloat py[1000];  // Variable not used
	VGfloat shapecolor[4];
	RGBA(255, 255, 128,1, shapecolor);

	printf("Entering LeandProcess\n");
	FinishedButton=0;
// Thread FFT

	pthread_create (&thfft,NULL, &DisplayFFT,NULL);

//END ThreadFFT

// Thread FFT

	pthread_create (&thbutton,NULL, &WaitButtonEvent,NULL);

//END ThreadFFT

	fp=popen(PATH_SCRIPT_LEAN, "r");
	if(fp==NULL) printf("Process error\n");

 while (((read = getline(&line, &len, fp)) != -1)&&(FinishedButton==0))
 {

        char  strTag[20];
	int NbData;
	static int Decim=0;
	sscanf(line,"%s ",strTag);
	char * token;
	static int Lock=0;
	static float SignalStrength=0;
	static float MER=0;
	static float FREQ=0;
	if((strcmp(strTag,"SYMBOLS")==0))
	{

		token = strtok(line," ");
		token = strtok(NULL," ");
		sscanf(token,"%d",&NbData);

		if(Decim%25==0)
		{
			//Start(wscreen,hscreen);
			Fill(255, 255, 255, 1);
			Roundrect(0,0,256,hscreen, 10, 10);
			BackgroundRGB(0,0,0,0);
			//Lock status
			char sLock[100];
			if(Lock==1)
			{
				strcpy(sLock,"Lock");
				Fill(0,255,0, 1);

			}
			else
			{
				strcpy(sLock,"----");
				Fill(255,0,0, 1);
			}
			Roundrect(200,0,100,50, 10, 10);
			Fill(255, 255, 255, 1);				   // White text
			Text(200, 20, sLock, SerifTypeface, 25);

			//Signal Strength
			char sSignalStrength[100];
			sprintf(sSignalStrength,"%3.0f",SignalStrength);

			Fill(255-SignalStrength,SignalStrength,0,1);
			Roundrect(350,0,20+SignalStrength/2,50, 10, 10);
			Fill(255, 255, 255, 1);				   // White text
			Text(350, 20, sSignalStrength, SerifTypeface, 25);

			//MER 2-30
			char sMER[100];
			sprintf(sMER,"%2.1fdB",MER);
			Fill(255-MER*8,(MER*8),0,1);
			Roundrect(500,0,(MER*8),50, 10, 10);
			Fill(255, 255, 255, 1);				   // White text
			Text(500,20, sMER, SerifTypeface, 25);
		}

		if(Decim%25==0)
		{
			static VGfloat PowerFFTx[FFT_SIZE];
			static VGfloat PowerFFTy[FFT_SIZE];
			StrokeWidth(2);

			Stroke(150, 150, 200, 0.8);
			int i;
			if(fftout!=NULL)
			{
			for(i=0;i<FFT_SIZE;i+=2)
			{

				PowerFFTx[i]=(i<FFT_SIZE/2)?(FFT_SIZE+i)/2:i/2;
				PowerFFTy[i]=log10f(sqrt(fftout[i][0]*fftout[i][0]+fftout[i][1]*fftout[i][1])/FFT_SIZE)*100;	
			Line(PowerFFTx[i],0,PowerFFTx[i],PowerFFTy[i]);
			//Polyline(PowerFFTx,PowerFFTy,FFT_SIZE);

			//Line(0, (i<1024/2)?(1024/2+i)/2:(i-1024/2)/2,  (int)sqrt(fftout[i][0]*fftout[i][0]+fftout[i][1]*fftout[i][1])*100/1024,(i<1024/2)?(1024/2+i)/2:(i-1024/2)/2);

			}
			//Polyline(PowerFFTx,PowerFFTy,FFT_SIZE);
			}
			//FREQ
			Stroke(0, 0, 255, 0.8);
			//Line(FFT_SIZE/2+FREQ/2/1024000.0,0,FFT_SIZE/2+FREQ/2/1024000.0,hscreen/2);
			Line(FFT_SIZE/2,0,FFT_SIZE/2,10);
			Stroke(0, 0, 255, 0.8);
			Line(0,hscreen-300,256,hscreen-300);
			StrokeWidth(10);
			Line(128+(FREQ/40000.0)*256.0,hscreen-300-20,128+(FREQ/40000.0)*256.0,hscreen-300+20);

			char sFreq[100];
			sprintf(sFreq,"%2.1fkHz",FREQ/1000.0);
			Text(0,hscreen-300+25, sFreq, SerifTypeface, 20);

		}
		if((Decim%25)==0)
		{
			int x,y;
			Decim++;
			int i;
			StrokeWidth(2);
			Stroke(255, 255, 128, 0.8);
			for(i=0;i<NbData;i++)
			{
				token=strtok(NULL," ");
				sscanf(token,"%d,%d",&x,&y);
				coordpoint(x+128, hscreen-(y+128), 5, shapecolor);

				Stroke(0, 255, 255, 0.8);
				Line(0,hscreen-128,256,hscreen-128);
				Line(128,hscreen,128,hscreen-256);

			}


			End();
			//usleep(40000);

		}
		else
			Decim++;
		/*if(Decim%1000==0)
		{
			char FileSave[255];
			FILE *File;
			sprintf(FileSave,"Snap%d_%dx%d.png",Decim,wscreen,hscreen);
			File=fopen(FileSave,"w");
			dumpscreen(wscreen,hscreen,File);
			fclose(File);
		}*/
		/*if(Decim>200)
		{
			Decim=0;
			Start(wscreen,hscreen);
		}*/

	}

	if((strcmp(strTag,"SS")==0))
	{
		token = strtok(line," ");
		token = strtok(NULL," ");
		sscanf(token,"%f",&SignalStrength);
		//printf("Signal %f\n",SignalStrength);
	}

	if((strcmp(strTag,"MER")==0))
	{

		token = strtok(line," ");
		token = strtok(NULL," ");
		sscanf(token,"%f",&MER);
		//printf("MER %f\n",MER);
	}

	if((strcmp(strTag,"FREQ")==0))
	{

		token = strtok(line," ");
		token = strtok(NULL," ");
		sscanf(token,"%f",&FREQ);
		//printf("FREQ %f\n",FREQ);
	}

	if((strcmp(strTag,"LOCK")==0))
	{

		token = strtok(line," ");
		token = strtok(NULL," ");
		sscanf(token,"%d",&Lock);
	}

	free(line);
	line=NULL;
    }
printf("End Lean - Clean\n");
usleep(5000000); // Time to FFT end reading samples
   pthread_join(thfft, NULL);
	//pclose(fp);
	pthread_join(thbutton, NULL);
	printf("End Lean\n");
}

void ReceiveStart()
{
	//system("sudo SDL_VIDEODRIVER=fbcon SDL_FBDEV=/dev/fb0 mplayer -ao /dev/null -vo sdl  /home/pi/rpidatv/video/mire250.ts &");
	//system(PATH_SCRIPT_LEAN);
	ProcessLeandvb();
}

void ReceiveStop()
{
	system("sudo killall leandvb");
	system("sudo killall hello_video.bin");
	//system("sudo killall mplayer");
}

static void
terminate(int dummy)
{
	printf("Terminate\n");
        char Commnd[255];
        sprintf(Commnd,"stty echo");
        system(Commnd);

	/*restoreterm();
	finish();*/
	exit(1);
}

// main initializes the system and shows the picture. 
// Exit and clean up when you hit [RETURN].
int main(int argc, char **argv) {
	// int n;  // not used?
	// char *progname = argv[0]; // not used?
	int NoDeviceEvent=0;
	saveterm();
	init(&wscreen, &hscreen);
	rawterm();
	int screenXmax, screenXmin;
	int screenYmax, screenYmin;
	int ReceiveDirect=0;
	int i;
        char Param[255];
        char Value[255];
 
// Catch sigaction and call terminate
	for (i = 0; i < 16; i++) {
		struct sigaction sa;

		memset(&sa, 0, sizeof(sa));
		sa.sa_handler = terminate;
		sigaction(i, &sa, NULL);
	}

// Determine if ReceiveDirect 2nd argument 
	if(argc>2)
		ReceiveDirect=atoi(argv[2]);

	if(ReceiveDirect==1)
	{
		//getTouchScreenDetails(&screenXmin,&screenXmax,&screenYmin,&screenYmax);
		 ProcessLeandvb(); // For FrMenu and no 
	}

// Check for presence of touchscreen
	for(NoDeviceEvent=0;NoDeviceEvent<5;NoDeviceEvent++)
	{
		if (openTouchScreen(NoDeviceEvent) == 1)
		{
			if(getTouchScreenDetails(&screenXmin,&screenXmax,&screenYmin,&screenYmax)==1) break;
		}
	}
	if(NoDeviceEvent==5) 
	{
		perror("No Touchscreen found");
		exit(1);
	}

// Calculate screen parameters
	scaleXvalue = ((float)screenXmax-screenXmin) / wscreen;
	//printf ("X Scale Factor = %f\n", scaleXvalue);
	scaleYvalue = ((float)screenYmax-screenYmin) / hscreen;
	//printf ("Y Scale Factor = %f\n", scaleYvalue);

// Define button grid
	int wbuttonsize=wscreen/5;
	int hbuttonsize=hscreen/6;

	// RESIZE JPEG TO BE DONE
	/*char PictureName[255];
	strcpy(PictureName,ImageFolder);
	GetNextPicture(PictureName);
	Image(0,0,300,200,PictureName);
	End();
	*/
	//ReceiveStart();
	waituntil(wscreen,hscreen,0x1b);
	restoreterm();
	finish();
	return 0;
}
