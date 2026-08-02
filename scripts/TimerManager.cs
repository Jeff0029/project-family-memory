using Godot;
using System;

public partial class TimerManager : Node
{
	[Signal]
	public delegate void TimerOverEventHandler();

	public event Action TimerOverEvt;

	[Export] private Label timeLabel;
	[Export] private Timer timer;

	private float timeRemaining = 60f;
	private bool hasFinished;

	public override void _Ready()
	{
		if (timer != null)
		{
			timer.WaitTime = 1f;
			timer.OneShot = false;
			timer.Timeout += OnTimerTimeout;
			timer.Start();
		}

		UpdateLabel();
	}

	private void OnTimerTimeout()
	{
		if (hasFinished)
		{
			return;
		}

		timeRemaining = Mathf.Max(0f, timeRemaining - 1f);
		UpdateLabel();

		if (timeRemaining <= 0f)
		{
			hasFinished = true;

			if (timer != null)
			{
				timer.Stop();
			}

			TimerOverEvt?.Invoke();
			EmitSignal(SignalName.TimerOver);
			GD.Print("Timer over.");
		}
	}

	private void UpdateLabel()
	{
		if (timeLabel != null)
		{
			timeLabel.Text = Mathf.CeilToInt(timeRemaining).ToString();
		}
	}

	public void StopTimer()
	{
		if (timer != null)
		{
			timer.Stop();
		}
	}
}
