<?php

namespace Dev\Kernel\Traits;

trait FieldHelper
{
    /**
     * @param mixed $data
     */
    public function saveCustomFields($model, $data)
    {
        $string = '[{"id":1,"title":"Contact General Extra Fields","items":[{"id":3,"title":"Facebook Ads ID","slug":"provider_ad_id_ad_id","instructions":"Facebook Ads ID","type":"text","options":{"defaultValue":null,"defaultValueTextarea":null,"placeholderText":"Facebook Ads ID","wysiwygToolbar":null,"selectChoices":null,"buttonLabel":null,"rows":null},"items":[],"value":""},{"id":2,"title":"Facebook Ads Form ID","slug":"provider_form_id","instructions":"Facebook Ads Form ID","type":"text","options":{"defaultValue":null,"defaultValueTextarea":null,"placeholderText":"Facebook Ads Form ID","wysiwygToolbar":null,"selectChoices":null,"buttonLabel":null,"rows":null},"items":[],"value":""},{"id":1,"title":"Facebook Form Name","slug":"provider_form_name","instructions":"Facebook Ads Form Name","type":"text","options":{"defaultValue":null,"defaultValueTextarea":null,"placeholderText":"Facebook Ads Form Name","wysiwygToolbar":null,"selectChoices":null,"buttonLabel":null,"rows":null},"items":[],"value":""},{"id":4,"title":"Facebook Ads Group ID","slug":"provider_adgroup_idoup_id","instructions":"Facebook Ads Group ID","type":"text","options":{"defaultValue":null,"defaultValueTextarea":null,"placeholderText":"Facebook Ads Group ID","wysiwygToolbar":null,"selectChoices":null,"buttonLabel":null,"rows":null},"items":[],"value":""},{"id":5,"title":"Leadgen ID","slug":"leadgen_id","instructions":"Leadgen ID","type":"text","options":{"defaultValue":null,"defaultValueTextarea":null,"placeholderText":"Leadgen ID","wysiwygToolbar":null,"selectChoices":null,"buttonLabel":null,"rows":null},"items":[],"value":""},{"id":6,"title":"Consumer ID","slug":"connection_id","instructions":"Consumer ID","type":"text","options":{"defaultValue":null,"defaultValueTextarea":null,"placeholderText":"Consumer ID","wysiwygToolbar":null,"selectChoices":null,"buttonLabel":null,"rows":null},"items":[],"value":""}]}]';
        $rows = $this->parseRawData($string);
        foreach ($rows as $row) {
            $row['value'] = $data[$row['slug']]; // Set custom field's value
            $this->saveCustomField(get_class($model), $model->id, $row);
        }
    }

    /**
     * @param string $jsonString
     * @return array
     */
    public function parseRawData($jsonString): array
    {
        try {
            $fieldGroups = json_decode($jsonString, true) ?: [];
        } catch (\Throwable $th) {
            return [];
        }

        $result = [];
        foreach ($fieldGroups as $fieldGroup) {
            foreach ($fieldGroup['items'] as $item) {
                $result[] = $item;
            }
        }
        return $result;
    }

    /**
     * @param string $reference
     * @param int $id
     * @param array $data
     */
    public function saveCustomField($reference, $id, array $data)
    {
        $currentMeta = $this->customFieldRepository->getFirstBy([
            'field_item_id' => $data['id'],
            'slug' => $data['slug'],
            'use_for' => $reference,
            'use_for_id' => $id,
        ]);

        $value = $this->parseFieldValue($data);

        if (!is_string($value)) {
            $value = json_encode($value);
        }

        $data['value'] = $value;

        if ($currentMeta) {
            $this->customFieldRepository->createOrUpdate($data, ['id' => $currentMeta->id]);
        } else {
            $data['use_for'] = $reference;
            $data['use_for_id'] = $id;
            $data['field_item_id'] = $data['id'];

            $this->customFieldRepository->create($data);
        }
    }


    /**
     * Get field value
     * @param array $field
     * @return array|string
     */
    protected function parseFieldValue($field)
    {
        $value = [];
        switch ($field['type']) {
            case 'repeater':
                if (!isset($field['value'])) {
                    break;
                }

                foreach ($field['value'] as $row) {
                    $groups = [];
                    foreach ($row as $item) {
                        $groups[] = [
                            'field_item_id' => $item['id'],
                            'type' => $item['type'],
                            'slug' => $item['slug'],
                            'value' => $this->parseFieldValue($item),
                        ];
                    }
                    $value[] = $groups;
                }
                break;
            case 'checkbox':
                $value = isset($field['value']) ? (array)$field['value'] : [];
                break;
            default:
                $value = isset($field['value']) ? $field['value'] : '';
                break;
        }
        return $value;
    }
}
