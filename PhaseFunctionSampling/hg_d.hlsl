// from https://research.nvidia.com/labs/rtr/approximate-mie/?fbclid=IwAR235jHUauDfiQhDiSRTcgQSPZG36sV-ruBgQ5DuUL_QkSC6gKhGR1bfygA
float DrainePhase(in float CosTheta, in float G, in float Alpha)
{
    return ((1 - G * G) * (1 + Alpha * CosTheta * CosTheta)) / (4. * (1 + (Alpha * (1 + 2 * G * G)) / 3.) * PI * pow(1 + G * G - 2 * G * CosTheta, 1.5));
}

float SamplePhaseFunction(in float PhaseCosTheta, in float PhaseG, in float PhaseG2, in float PhaseBlend)
{
	float MiePhaseValueLight0 = 0.0f;
	float MiePhaseValueLight1 = 0.0f;
	float Phase = 0.0f;

	if(PhaseG < 1.001f && PhaseG2 < 1.001f) 
	{ // HENYEY-GREENSTEIN BLEND: DEFAULT METHOD
		PhaseG = clamp(PhaseG, -0.999f, 0.999f);
		PhaseG2 = clamp(PhaseG2, -0.999f, 0.999f);
		PhaseBlend = clamp(PhaseBlend, 0.0f, 1.0f);
		MiePhaseValueLight0 = HenyeyGreensteinPhase(PhaseG, -PhaseCosTheta);	// negate cosTheta because due to WorldDir being a "in" direction. 
		MiePhaseValueLight1 = HenyeyGreensteinPhase(PhaseG2, -PhaseCosTheta);
		Phase = MiePhaseValueLight0 + PhaseBlend * (MiePhaseValueLight1 - MiePhaseValueLight0);
	}
	else
	{ // HENYEY-GREENSTEIN and DRAINE BLEND: TESTING METHOD
		// use PhaseBlend variable as particle size (d variable in the article)
		float PhaseHG = 0.0f;
		float PhaseD = 0.0f;
		float PhaseAlpha = 0.0f;
		float NewPhaseBlend = 0.0f;
		
		// Small particles
		if(PhaseBlend <= 0.1f)
		{
			PhaseHG = 13.8f * PhaseBlend * PhaseBlend;
			PhaseD = 1.1456f * PhaseBlend * sin(9.29044f * PhaseBlend);
			PhaseAlpha = 250.0f;
			NewPhaseBlend = 0.252977f - 312.983f * pow(PhaseBlend, 4.3f);
		}
		else
		{	
			//  Mid-range particles
			if(PhaseBlend > 0.1f && PhaseBlend < 1.5f)
			{
				float LogD = log(PhaseBlend);
				PhaseHG = 0.862f - 0.143f * LogD * LogD;
				PhaseD = 0.379685f * cos(1.19692f * cos((LogD - 0.238604f)*(LogD + 1.00667f)/(0.507522f - 0.15677f * LogD)) + 1.37932f * LogD + 0.0625835f) + 0.344213f;
				PhaseAlpha = 250.0f;
				NewPhaseBlend = 0.146209f * cos(3.38707f * LogD + 2.11193f) + 0.316072f + 0.0778917f * LogD;
			}
			else
			{
				// Mid-range particles
				if(PhaseBlend >= 1.5f && PhaseBlend < 5.0f)
				{
					float LogD = log(PhaseBlend);
					PhaseHG = 0.0604931f * log(LogD) + 0.940256f;
					PhaseD = 0.500411f - (0.081287f / (-2.0f * LogD + tan(LogD) + 1.27551f));
					PhaseAlpha = 7.30354f * LogD + 6.31675f;
					NewPhaseBlend = 0.026914f * (LogD - cos(5.68947f * (log(LogD) - 0.0292149f))) + 0.376475f;
				}
				// Large particles
				else
				{
					PhaseHG = exp(-0.0990567f / (PhaseBlend - 1.67154f));
					PhaseD = exp(-2.20679f / (PhaseBlend + 3.91029f) - 0.428934f);
					PhaseAlpha = exp(3.62489f - (8.29288f / (PhaseBlend + 5.52825f)));
					NewPhaseBlend = exp(-0.599085f / (PhaseBlend - 0.641583f) - 0.665888f);
				}
			}
		}
		
		MiePhaseValueLight0 = HenyeyGreensteinPhase(PhaseHG, -PhaseCosTheta);	// negate cosTheta because due to WorldDir being a "in" direction. 
		MiePhaseValueLight1 = DrainePhase(-PhaseCosTheta, PhaseD, PhaseAlpha);
		//Phase = (1.0 - NewPhaseBlend) * MiePhaseValueLight0 + NewPhaseBlend * MiePhaseValueLight1;
		Phase = MiePhaseValueLight0 + NewPhaseBlend * (MiePhaseValueLight1 - MiePhaseValueLight0);
	}
	
	return Phase;
}
