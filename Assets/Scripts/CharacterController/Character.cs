using System;
using UnityEngine;

[RequireComponent(typeof(CharacterController))]
public class Character : MonoBehaviour
{
    [SerializeField] private Camera PlayerCamera;
    [SerializeField] private float WalkSpeed = 3.0f;

    private CharacterController _cc;

    private Transform _cameraTransform;
    private Quaternion _initialCameraRotation;
    private float _cameraXEulerOffset;

    private void Awake()
    {
        _cc = GetComponent<CharacterController>();
        _cameraTransform = PlayerCamera.transform;
        _initialCameraRotation = _cameraTransform.localRotation;
    }

    private void Update()
    {
        // Character rotation.
        transform.Rotate(0f, Input.GetAxis("Mouse X") * 2f, 0f);

        // Camera rotation.
        _cameraXEulerOffset += -Input.GetAxis("Mouse Y") * 2f;
        _cameraXEulerOffset = Mathf.Clamp(_cameraXEulerOffset, -90f, 90f);

        _cameraTransform.localRotation = _initialCameraRotation * Quaternion.Euler(new Vector3(_cameraXEulerOffset, 0f, 0f));

        // Character movement.
        Vector2 inputMoveVector = default;
        inputMoveVector += Vector2.right * Input.GetAxis("Horizontal");
        inputMoveVector += Vector2.up * Input.GetAxis("Vertical");

        inputMoveVector.Normalize();

        Vector3 moveVector = transform.rotation * new Vector3(inputMoveVector.x, 0f, inputMoveVector.y);
        _cc.SimpleMove(moveVector * WalkSpeed);
    }
}
