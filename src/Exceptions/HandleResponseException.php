<?php

/**
 * © 2026 VISUAL WEBER COMPANY LIMITED. All rights reserved.
 * Proprietary software developed and distributed by Visual Weber.
 * Use is permitted only under a valid license agreement.
 *
 * © 2026 CÔNG TY TNHH VISUAL WEBER. Bảo lưu mọi quyền.
 * Phần mềm độc quyền của Visual Weber, chỉ được sử dụng theo Hợp đồng cấp phép.
 */

namespace Dev\Kernel\Exceptions;

use Dev\Base\Http\Responses\BaseHttpResponse;
use Symfony\Component\HttpFoundation\Response;
use Illuminate\Support\Facades\Log;

class HandleResponseException extends BaseHttpResponse
{
    /**
     * @var string
     */
    protected $message_system;

    /**
     * @return string
     */
    public function getMessageSystem(): string
    {
        return $this->message_system;
    }

    /**
     * @param string $message
     * @return BaseHttpResponse
     */
    public function setMessageSystem($message_system): self
    {
        $this->message_system = $message_system;

        return $this;
    }

    public function serverInternalResponse($message = null)
    {
        Log::error(@$message);
        $this->setMessageSystem(@$message);

        return $this
            ->setError(true)
            ->setData([
                'message_system' => @$message
            ])
            ->setMessage(__('Có một lỗi đã xảy ra. Vui lòng liên hệ với quản trị viên để biết cách khắc phục.'))
            ->setCode(Response::HTTP_INTERNAL_SERVER_ERROR);
    }

    public function clientInternalResponse($message = null)
    {
        return $this
            ->setError()
            ->setMessage($message ? $message : __('Có một lỗi đã xảy ra. Vui lòng liên hệ với quản trị viên để biết cách khắc phục.'))
            ->setCode(Response::HTTP_BAD_REQUEST);
    }

    public function dataNotFoundResponse()
    {
        return $this
            ->setError()
            ->setMessage(__("Xin lỗi! Dữ liệu này không tồn tại."))
            ->setCode(Response::HTTP_NOT_FOUND);
    }

    public function notExistsInTrash()
    {
        return $this
            ->setError()
            ->setMessage(__("Có lỗi xảy ra! Dữ liệu này không tồn tại trong thùng rác. Vui lòng kiểm tra lại."))
            ->setCode(Response::HTTP_NOT_FOUND);
    }

    public function canNotDoThisAction()
    {
        return $this
            ->setError()
            ->setMessage(__("Xin lỗi! Bạn không thể thực hiện hành động này. Vì quyền bị từ chối!"))
            ->setCode(Response::HTTP_FORBIDDEN);
    }
}
