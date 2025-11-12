<?php

namespace Dev\Support\Repositories\Caches;

use Dev\Base\Models\BaseModel;
use Dev\Base\Models\BaseQueryBuilder;
use Dev\Support\Repositories\Interfaces\RepositoryInterface;
use Dev\Support\Services\Cache\Cache;
use Illuminate\Database\Eloquent\Model;
use Exception;
use InvalidArgumentException;

/**
 * @deprecated
 */
abstract class CacheAbstractDecorator implements RepositoryInterface
{
    protected RepositoryInterface $repository;
	protected Cache $cache;

	public function __construct(RepositoryInterface $repository, string $cacheGroup = null, string $modeGroup = null)
	{
		$this->repository = $repository;
		$this->cache = new Cache(app('cache'), $cacheGroup ?? get_class($repository->getModel()), [], $modeGroup);
    }

    public function getDataWithCache(string $function, array $args) { try { if (! setting('enable_cache_data', false)) { return call_user_func_array([$this->repository, $function], $args); } $cacheKey = md5( get_class($this) . $function . serialize(request()->input()) . serialize(json_encode()) );  if ($this->cache->has($cacheKey)) { return $this->cache->get($cacheKey); }  $cacheData = call_user_func_array([$this->repository, $function], $args);  $this->cache->put($cacheKey, $cacheData);  return $cacheData; } catch (Exception | InvalidArgumentException $ex) { info($ex->getMessage()); return call_user_func_array([$this->repository, $function], $args); } }

	public function getDataIfExistCache(string $function, array $args){

        return call_user_func_array([$this->repository, $function], $args);
    }

    public function getDataWithoutCache(string $function, array $args)
    {
        return call_user_func_array([$this->repository, $function], $args);
    }

    public function flushCacheAndUpdateData(string $function, array $args)
    {
        return call_user_func_array([$this->repository, $function], $args);
    }

    public function getModel()
    {
        return $this->repository->getModel();
    }

    public function setModel(BaseModel|BaseQueryBuilder $model): self
    {
        $this->repository->setModel($model);

        return $this;
    }

    public function getTable(): string
    {
        return $this->repository->getTable();
    }

    public function applyBeforeExecuteQuery($data, bool $isSingle = false)
    {
        return $this->repository->applyBeforeExecuteQuery($data, $isSingle);
    }

    public function make(array $with = [])
    {
        return $this->repository->make($with);
    }

    public function findById($id, array $with = [])
    {
        return $this->getDataIfExistCache(__FUNCTION__, func_get_args());
    }

    public function findOrFail($id, array $with = [])
    {
        return $this->getDataIfExistCache(__FUNCTION__, func_get_args());
    }

    public function getFirstBy(array $condition = [], array $select = [], array $with = [])
    {
        return $this->getDataIfExistCache(__FUNCTION__, func_get_args());
    }

    public function pluck(string $column, $key = null, array $condition = []): array
    {
        return $this->getDataIfExistCache(__FUNCTION__, func_get_args());
    }

    public function all(array $with = [])
    {
        return $this->getDataIfExistCache(__FUNCTION__, func_get_args());
    }

    public function allBy(array $condition, array $with = [], array $select = ['*'])
    {
        return $this->getDataIfExistCache(__FUNCTION__, func_get_args());
    }

    public function create(array $data)
    {
        return $this->flushCacheAndUpdateData(__FUNCTION__, func_get_args());
    }

    public function createOrUpdate($data, array $condition = [])
    {
        return $this->flushCacheAndUpdateData(__FUNCTION__, func_get_args());
    }

    public function delete(Model $model): ?bool
    {
        return $this->flushCacheAndUpdateData(__FUNCTION__, func_get_args());
    }

    public function firstOrCreate(array $data, array $with = [])
    {
        return $this->flushCacheAndUpdateData(__FUNCTION__, func_get_args());
    }

    public function update(array $condition, array $data): int
    {
        return $this->flushCacheAndUpdateData(__FUNCTION__, func_get_args());
    }

    public function select(array $select = ['*'], array $condition = [])
    {
        return $this->getDataWithoutCache(__FUNCTION__, func_get_args());
    }

    public function deleteBy(array $condition = []): bool
    {
        return $this->flushCacheAndUpdateData(__FUNCTION__, func_get_args());
    }

    public function count(array $condition = []): int
    {
        return $this->getDataIfExistCache(__FUNCTION__, func_get_args());
    }

    public function getByWhereIn($column, array $value = [], array $args = [])
    {
        return $this->getDataIfExistCache(__FUNCTION__, func_get_args());
    }

    public function advancedGet(array $params = [])
    {
        return $this->getDataIfExistCache(__FUNCTION__, func_get_args());
    }

    public function forceDelete(array $condition = [])
    {
        return $this->flushCacheAndUpdateData(__FUNCTION__, func_get_args());
    }

    public function restoreBy(array $condition = [])
    {
        return $this->flushCacheAndUpdateData(__FUNCTION__, func_get_args());
    }

    public function getFirstByWithTrash(array $condition = [], array $select = [])
    {
        return $this->getDataIfExistCache(__FUNCTION__, func_get_args());
    }

    public function insert(array $data): bool
    {
        return $this->flushCacheAndUpdateData(__FUNCTION__, func_get_args());
    }

    public function firstOrNew(array $condition)
    {
        return $this->getDataIfExistCache(__FUNCTION__, func_get_args());
    }
}
