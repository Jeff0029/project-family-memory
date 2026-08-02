using Godot;
using System;

/// <summary>
/// Lets the player move, rotate, scale, and fade an image before submitting the final placement.
/// </summary>
public partial class ImagePlacer : Node
{
	[Export] private TimerManager timerManager;
	[Export] private Sprite2D imageToPlace;

	private const float MinOpacity = 0.1f;
	private const float MaxOpacity = 1f;
	private const float RotationSpeed = 90f;
	private const float OpacitySpeed = 0.35f;
	private bool hasSubmitted;

	public override void _Ready()
	{

		if (timerManager != null)
		{
			timerManager.TimerOverEvt += OnTimerOver;
		}

		ApplyStartingState();
	}

	public override void _Process(double delta)
	{
		if (hasSubmitted || imageToPlace == null)
		{
			return;
		}

		imageToPlace.Position = GetViewport().GetMousePosition();

		if (Input.IsKeyPressed(Key.A))
		{
			imageToPlace.RotationDegrees -= RotationSpeed * (float)delta;
		}
		else if (Input.IsKeyPressed(Key.D))
		{
			imageToPlace.RotationDegrees += RotationSpeed * (float)delta;
		}

		if (Input.IsKeyPressed(Key.W))
		{
			var color = imageToPlace.Modulate;
			color.A = Mathf.Clamp(color.A + OpacitySpeed * (float)delta, MinOpacity, MaxOpacity);
			imageToPlace.Modulate = color;
		}
		else if (Input.IsKeyPressed(Key.S))
		{
			var color = imageToPlace.Modulate;
			color.A = Mathf.Clamp(color.A - OpacitySpeed * (float)delta, MinOpacity, MaxOpacity);
			imageToPlace.Modulate = color;
		}
	}

	public override void _Input(InputEvent @event)
	{
		if (hasSubmitted || imageToPlace == null)
		{
			return;
		}

		if (@event is InputEventMouseButton mouseButton)
		{
			if (mouseButton.Pressed && mouseButton.ButtonIndex == MouseButton.Left)
			{
				SubmitPlacement();
			}
			else if (mouseButton.Pressed && mouseButton.ButtonIndex == MouseButton.WheelUp)
			{
				imageToPlace.Scale *= 1.05f;
			}
			else if (mouseButton.Pressed && mouseButton.ButtonIndex == MouseButton.WheelDown)
			{
				imageToPlace.Scale *= 0.95f;
			}
		}
	}

	private void OnTimerOver()
	{
		SubmitPlacement();
	}

	private void SubmitPlacement()
	{
		if (hasSubmitted)
		{
			return;
		}

		hasSubmitted = true;

		if (timerManager != null)
		{
			timerManager.StopTimer();
		}

		SetProcess(false);
		SetPhysicsProcess(false);
		SetProcessInput(false);

		GD.Print("Image placement submitted.");
	}

	private void ApplyStartingState()
	{
		if (imageToPlace == null)
		{
			return;
		}

		imageToPlace.Modulate = new Color(1f, 1f, 1f, 1f);
		imageToPlace.Scale = Vector2.One;
		imageToPlace.RotationDegrees = 0f;
	}
}
